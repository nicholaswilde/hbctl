use std::collections::{BTreeMap, BTreeSet};
use std::sync::OnceLock;

use regex::Regex;
use serde::Serialize;

use crate::client::models::Entity;

const STOP_WORDS: &[&str] = &[
    "module",
    "board",
    "breakout",
    "kit",
    "sensor",
    "shield",
    "adapter",
    "converter",
    "charger",
    "type",
    "usb",
];

fn version_regex() -> &'static Regex {
    static RE: OnceLock<Regex> = OnceLock::new();
    RE.get_or_init(|| Regex::new(r"(?i)\bv?\d+(\.\d+)*\b").expect("valid version regex"))
}

/// Normalize an entity name into a token set for Pass 2 Jaccard similarity:
/// lowercased, version numbers (`\bv?\d+(\.\d+)*\b`) and punctuation stripped,
/// stop-words filtered.
pub fn normalize_tokens(name: &str) -> BTreeSet<String> {
    let lower = name.to_ascii_lowercase();
    let without_versions = version_regex().replace_all(&lower, " ");

    without_versions
        .split(|c: char| !c.is_alphanumeric())
        .map(str::trim)
        .filter(|tok| !tok.is_empty() && !STOP_WORDS.contains(tok))
        .map(ToOwned::to_owned)
        .collect()
}

/// Compute Jaccard similarity (`|A ∩ B| / |A ∪ B|`) between two token sets.
/// Returns `0.0` when either set is empty.
pub fn jaccard_similarity(a: &BTreeSet<String>, b: &BTreeSet<String>) -> f64 {
    if a.is_empty() || b.is_empty() {
        return 0.0;
    }
    let intersection = a.intersection(b).count();
    let union = a.union(b).count();
    if union == 0 {
        0.0
    } else {
        (intersection as f64) / (union as f64)
    }
}

/// Duplicate match classification.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum MatchKind {
    Exact,
    Near,
}

impl std::fmt::Display for MatchKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Exact => write!(f, "exact"),
            Self::Near => write!(f, "near"),
        }
    }
}

/// Compact representation of an item inside a duplicate cluster.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct DedupMember {
    pub id: String,
    pub name: String,
    pub quantity: i64,
}

impl From<&Entity> for DedupMember {
    fn from(entity: &Entity) -> Self {
        Self {
            id: entity.id.clone(),
            name: entity.name.clone(),
            quantity: entity.quantity,
        }
    }
}

/// Detected cluster of duplicate items with selected keeper and duplicates to remove.
#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct DuplicateCluster {
    pub match_kind: MatchKind,
    pub similarity: f64,
    pub keeper: DedupMember,
    pub duplicates: Vec<DedupMember>,
    pub merged_quantity: i64,
}

/// Select keeper index from candidate `(original_idx, entity)` entries:
/// 1. Longest trimmed name (then longest raw name)
/// 2. Highest quantity
/// 3. First encountered (lowest original index)
pub fn select_keeper_index(candidates: &[(usize, &Entity)]) -> usize {
    let best = candidates
        .iter()
        .max_by(|(idx_a, a), (idx_b, b)| {
            a.name
                .trim()
                .chars()
                .count()
                .cmp(&b.name.trim().chars().count())
                .then_with(|| a.name.chars().count().cmp(&b.name.chars().count()))
                .then_with(|| a.quantity.cmp(&b.quantity))
                .then_with(|| idx_b.cmp(idx_a)) // smaller original index wins
        })
        .expect("candidates must be non-empty");
    best.0
}

/// Run the two-pass duplicate detection engine:
/// - Pass 1 (Exact): Case-insensitive trimmed name matches.
/// - Pass 2 (Near): Jaccard similarity (`>= threshold`) on normalized tokens.
pub fn find_duplicates(entities: &[Entity], threshold: f64) -> Vec<DuplicateCluster> {
    let mut clusters = Vec::new();
    let mut consumed = vec![false; entities.len()];

    // Pass 1: Exact case-insensitive trimmed name matches
    let mut exact_groups: BTreeMap<String, Vec<usize>> = BTreeMap::new();
    for (idx, entity) in entities.iter().enumerate() {
        let key = entity.name.trim().to_ascii_lowercase();
        if !key.is_empty() {
            exact_groups.entry(key).or_default().push(idx);
        }
    }

    // Order exact clusters by first encountered index for deterministic output
    let mut exact_list: Vec<Vec<usize>> = exact_groups
        .into_values()
        .filter(|group| group.len() >= 2)
        .collect();
    exact_list.sort_by_key(|group| group[0]);

    for group in exact_list {
        for &idx in &group {
            consumed[idx] = true;
        }
        clusters.push(build_cluster(entities, &group, MatchKind::Exact, 1.0));
    }

    // Pass 2: Near duplicates via Jaccard similarity on normalized tokens
    let remaining: Vec<usize> = (0..entities.len()).filter(|&i| !consumed[i]).collect();
    let token_sets: Vec<BTreeSet<String>> = remaining
        .iter()
        .map(|&idx| normalize_tokens(&entities[idx].name))
        .collect();

    let n = remaining.len();
    let mut parent: Vec<usize> = (0..n).collect();
    let mut edge_sims: Vec<(usize, usize, f64)> = Vec::new();

    for i in 0..n {
        if token_sets[i].is_empty() {
            continue;
        }
        for j in (i + 1)..n {
            if token_sets[j].is_empty() {
                continue;
            }
            let sim = jaccard_similarity(&token_sets[i], &token_sets[j]);
            if sim >= threshold {
                dsu_union(&mut parent, i, j);
                edge_sims.push((i, j, sim));
            }
        }
    }

    let mut components: BTreeMap<usize, Vec<usize>> = BTreeMap::new();
    for i in 0..n {
        let root = dsu_find(&mut parent, i);
        components.entry(root).or_default().push(i);
    }

    let mut near_groups: Vec<Vec<usize>> = components
        .into_values()
        .filter(|comp| comp.len() >= 2)
        .collect();
    near_groups.sort_by_key(|comp| remaining[comp[0]]);

    for comp in near_groups {
        let orig_indices: Vec<usize> = comp.iter().map(|&local| remaining[local]).collect();
        let comp_set: BTreeSet<usize> = comp.iter().copied().collect();
        let min_sim = edge_sims
            .iter()
            .filter(|(a, b, _)| comp_set.contains(a) && comp_set.contains(b))
            .map(|(_, _, s)| *s)
            .fold(1.0_f64, f64::min);
        clusters.push(build_cluster(
            entities,
            &orig_indices,
            MatchKind::Near,
            min_sim,
        ));
    }

    clusters
}

fn build_cluster(
    entities: &[Entity],
    indices: &[usize],
    match_kind: MatchKind,
    similarity: f64,
) -> DuplicateCluster {
    let candidates: Vec<(usize, &Entity)> = indices.iter().map(|&i| (i, &entities[i])).collect();
    let keeper_idx = select_keeper_index(&candidates);
    let keeper = DedupMember::from(&entities[keeper_idx]);

    let duplicates: Vec<DedupMember> = indices
        .iter()
        .copied()
        .filter(|&i| i != keeper_idx)
        .map(|i| DedupMember::from(&entities[i]))
        .collect();

    let merged_quantity = keeper.quantity + duplicates.iter().map(|d| d.quantity).sum::<i64>();

    DuplicateCluster {
        match_kind,
        similarity,
        keeper,
        duplicates,
        merged_quantity,
    }
}

fn dsu_find(parent: &mut [usize], mut x: usize) -> usize {
    while parent[x] != x {
        parent[x] = parent[parent[x]];
        x = parent[x];
    }
    x
}

fn dsu_union(parent: &mut [usize], a: usize, b: usize) {
    let ra = dsu_find(parent, a);
    let rb = dsu_find(parent, b);
    if ra != rb {
        if ra < rb {
            parent[rb] = ra;
        } else {
            parent[ra] = rb;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn mk_entity(id: &str, name: &str, qty: i64) -> Entity {
        Entity {
            id: id.to_string(),
            name: name.to_string(),
            quantity: qty,
            ..Default::default()
        }
    }

    #[test]
    fn test_normalize_tokens_strips_versions_punctuation_and_stop_words() {
        let a = normalize_tokens("BME280 Sensor Module v2.1");
        let b = normalize_tokens("BME280 Breakout Board");
        assert_eq!(a, BTreeSet::from(["bme280".to_string()]));
        assert_eq!(a, b);
        assert_eq!(jaccard_similarity(&a, &b), 1.0);

        let c = normalize_tokens("ESP32-S3 DevKit USB-C Charger Adapter 1.0");
        assert_eq!(
            c,
            BTreeSet::from([
                "c".to_string(),
                "devkit".to_string(),
                "esp32".to_string(),
                "s3".to_string()
            ])
        );
    }

    #[test]
    fn test_jaccard_similarity_edge_cases() {
        let empty: BTreeSet<String> = BTreeSet::new();
        let a = BTreeSet::from(["esp32".into(), "devkit".into(), "wifi".into(), "ble".into()]);
        let b = BTreeSet::from([
            "esp32".into(),
            "devkit".into(),
            "wifi".into(),
            "ble".into(),
            "pro".into(),
        ]);
        assert_eq!(jaccard_similarity(&empty, &empty), 0.0);
        assert_eq!(jaccard_similarity(&a, &empty), 0.0);
        assert!((jaccard_similarity(&a, &b) - 0.8).abs() < 1e-9);
    }

    #[test]
    fn test_keeper_selection_priority() {
        // 1. Longest name wins
        let e1 = mk_entity("1", "BME280", 10);
        let e2 = mk_entity("2", "BME280 Temperature Sensor", 1);
        assert_eq!(select_keeper_index(&[(0, &e1), (1, &e2)]), 1);

        // 2. Tie on name length -> highest quantity wins
        let e3 = mk_entity("3", "ESP32 DevKit", 2);
        let e4 = mk_entity("4", "esp32 devkit", 5);
        assert_eq!(select_keeper_index(&[(0, &e3), (1, &e4)]), 1);

        // 3. Tie on name length and quantity -> first encountered wins
        let e5 = mk_entity("5", "ESP32 DevKit", 3);
        let e6 = mk_entity("6", "esp32 devkit", 3);
        assert_eq!(select_keeper_index(&[(0, &e5), (1, &e6)]), 0);
    }

    #[test]
    fn test_two_pass_clustering() {
        let entities = vec![
            mk_entity("1", "USB-C Cable", 2),
            mk_entity("2", "  usb-c cable ", 4),
            mk_entity("3", "BME280 Sensor Module v1.0", 1),
            mk_entity("4", "BME280 Breakout Board", 3),
            mk_entity("5", "Fluke 87V Multimeter", 1),
        ];

        let clusters = find_duplicates(&entities, 0.8);
        assert_eq!(clusters.len(), 2);

        // Pass 1: exact cluster
        assert_eq!(clusters[0].match_kind, MatchKind::Exact);
        assert_eq!(clusters[0].keeper.id, "2"); // same trimmed len, higher quantity
        assert_eq!(clusters[0].duplicates.len(), 1);
        assert_eq!(clusters[0].duplicates[0].id, "1");
        assert_eq!(clusters[0].merged_quantity, 6);

        // Pass 2: near cluster
        assert_eq!(clusters[1].match_kind, MatchKind::Near);
        assert_eq!(clusters[1].keeper.id, "3"); // longer name wins
        assert_eq!(clusters[1].duplicates.len(), 1);
        assert_eq!(clusters[1].duplicates[0].id, "4");
        assert_eq!(clusters[1].merged_quantity, 4);
    }

    #[test]
    fn test_dedup_match_kind_display_and_dsu_union_order() {
        assert_eq!(MatchKind::Exact.to_string(), "exact");
        assert_eq!(MatchKind::Near.to_string(), "near");

        // Trigger dsu_union when ra > rb (e.g. union(2, 0))
        let mut parent = vec![0, 1, 2, 3];
        dsu_union(&mut parent, 2, 0);
        assert_eq!(dsu_find(&mut parent, 2), dsu_find(&mut parent, 0));

        // Empty-token entities are skipped in Pass 2 without clustering
        let entities = vec![
            mk_entity("1", "Sensor Module", 1),
            mk_entity("2", "Board Kit", 1),
            mk_entity("3", "UniqueThing", 1),
        ];
        assert!(find_duplicates(&entities, 0.8).is_empty());
    }
}
