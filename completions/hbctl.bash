_hbctl() {
    local i cur prev opts cmd
    COMPREPLY=()
    if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
        cur="$2"
    else
        cur="${COMP_WORDS[COMP_CWORD]}"
    fi
    prev="$3"
    cmd=""
    opts=""

    for i in "${COMP_WORDS[@]:0:COMP_CWORD}"
    do
        case "${cmd},${i}" in
            ",$1")
                cmd="hbctl"
                ;;
            hbctl,attachment)
                cmd="hbctl__subcmd__attachment"
                ;;
            hbctl,auth)
                cmd="hbctl__subcmd__auth"
                ;;
            hbctl,completions)
                cmd="hbctl__subcmd__completions"
                ;;
            hbctl,entity-type)
                cmd="hbctl__subcmd__entity__subcmd__types"
                ;;
            hbctl,entity-types)
                cmd="hbctl__subcmd__entity__subcmd__types"
                ;;
            hbctl,export)
                cmd="hbctl__subcmd__export"
                ;;
            hbctl,field)
                cmd="hbctl__subcmd__field"
                ;;
            hbctl,help)
                cmd="hbctl__subcmd__help"
                ;;
            hbctl,item)
                cmd="hbctl__subcmd__item"
                ;;
            hbctl,man)
                cmd="hbctl__subcmd__man"
                ;;
            hbctl,search)
                cmd="hbctl__subcmd__search"
                ;;
            hbctl,self-update)
                cmd="hbctl__subcmd__update"
                ;;
            hbctl,status)
                cmd="hbctl__subcmd__status"
                ;;
            hbctl,tag)
                cmd="hbctl__subcmd__tag"
                ;;
            hbctl,update)
                cmd="hbctl__subcmd__update"
                ;;
            hbctl__subcmd__attachment,delete)
                cmd="hbctl__subcmd__attachment__subcmd__delete"
                ;;
            hbctl__subcmd__attachment,download)
                cmd="hbctl__subcmd__attachment__subcmd__download"
                ;;
            hbctl__subcmd__attachment,help)
                cmd="hbctl__subcmd__attachment__subcmd__help"
                ;;
            hbctl__subcmd__attachment,list)
                cmd="hbctl__subcmd__attachment__subcmd__list"
                ;;
            hbctl__subcmd__attachment,upload)
                cmd="hbctl__subcmd__attachment__subcmd__upload"
                ;;
            hbctl__subcmd__attachment__subcmd__help,delete)
                cmd="hbctl__subcmd__attachment__subcmd__help__subcmd__delete"
                ;;
            hbctl__subcmd__attachment__subcmd__help,download)
                cmd="hbctl__subcmd__attachment__subcmd__help__subcmd__download"
                ;;
            hbctl__subcmd__attachment__subcmd__help,help)
                cmd="hbctl__subcmd__attachment__subcmd__help__subcmd__help"
                ;;
            hbctl__subcmd__attachment__subcmd__help,list)
                cmd="hbctl__subcmd__attachment__subcmd__help__subcmd__list"
                ;;
            hbctl__subcmd__attachment__subcmd__help,upload)
                cmd="hbctl__subcmd__attachment__subcmd__help__subcmd__upload"
                ;;
            hbctl__subcmd__auth,help)
                cmd="hbctl__subcmd__auth__subcmd__help"
                ;;
            hbctl__subcmd__auth,login)
                cmd="hbctl__subcmd__auth__subcmd__login"
                ;;
            hbctl__subcmd__auth,logout)
                cmd="hbctl__subcmd__auth__subcmd__logout"
                ;;
            hbctl__subcmd__auth,refresh)
                cmd="hbctl__subcmd__auth__subcmd__refresh"
                ;;
            hbctl__subcmd__auth,status)
                cmd="hbctl__subcmd__auth__subcmd__status"
                ;;
            hbctl__subcmd__auth__subcmd__help,help)
                cmd="hbctl__subcmd__auth__subcmd__help__subcmd__help"
                ;;
            hbctl__subcmd__auth__subcmd__help,login)
                cmd="hbctl__subcmd__auth__subcmd__help__subcmd__login"
                ;;
            hbctl__subcmd__auth__subcmd__help,logout)
                cmd="hbctl__subcmd__auth__subcmd__help__subcmd__logout"
                ;;
            hbctl__subcmd__auth__subcmd__help,refresh)
                cmd="hbctl__subcmd__auth__subcmd__help__subcmd__refresh"
                ;;
            hbctl__subcmd__auth__subcmd__help,status)
                cmd="hbctl__subcmd__auth__subcmd__help__subcmd__status"
                ;;
            hbctl__subcmd__entity__subcmd__types,create)
                cmd="hbctl__subcmd__entity__subcmd__types__subcmd__create"
                ;;
            hbctl__subcmd__entity__subcmd__types,delete)
                cmd="hbctl__subcmd__entity__subcmd__types__subcmd__delete"
                ;;
            hbctl__subcmd__entity__subcmd__types,help)
                cmd="hbctl__subcmd__entity__subcmd__types__subcmd__help"
                ;;
            hbctl__subcmd__entity__subcmd__types,list)
                cmd="hbctl__subcmd__entity__subcmd__types__subcmd__list"
                ;;
            hbctl__subcmd__entity__subcmd__types__subcmd__help,create)
                cmd="hbctl__subcmd__entity__subcmd__types__subcmd__help__subcmd__create"
                ;;
            hbctl__subcmd__entity__subcmd__types__subcmd__help,delete)
                cmd="hbctl__subcmd__entity__subcmd__types__subcmd__help__subcmd__delete"
                ;;
            hbctl__subcmd__entity__subcmd__types__subcmd__help,help)
                cmd="hbctl__subcmd__entity__subcmd__types__subcmd__help__subcmd__help"
                ;;
            hbctl__subcmd__entity__subcmd__types__subcmd__help,list)
                cmd="hbctl__subcmd__entity__subcmd__types__subcmd__help__subcmd__list"
                ;;
            hbctl__subcmd__field,delete)
                cmd="hbctl__subcmd__field__subcmd__delete"
                ;;
            hbctl__subcmd__field,get)
                cmd="hbctl__subcmd__field__subcmd__get"
                ;;
            hbctl__subcmd__field,help)
                cmd="hbctl__subcmd__field__subcmd__help"
                ;;
            hbctl__subcmd__field,list)
                cmd="hbctl__subcmd__field__subcmd__list"
                ;;
            hbctl__subcmd__field,set)
                cmd="hbctl__subcmd__field__subcmd__set"
                ;;
            hbctl__subcmd__field__subcmd__help,delete)
                cmd="hbctl__subcmd__field__subcmd__help__subcmd__delete"
                ;;
            hbctl__subcmd__field__subcmd__help,get)
                cmd="hbctl__subcmd__field__subcmd__help__subcmd__get"
                ;;
            hbctl__subcmd__field__subcmd__help,help)
                cmd="hbctl__subcmd__field__subcmd__help__subcmd__help"
                ;;
            hbctl__subcmd__field__subcmd__help,list)
                cmd="hbctl__subcmd__field__subcmd__help__subcmd__list"
                ;;
            hbctl__subcmd__field__subcmd__help,set)
                cmd="hbctl__subcmd__field__subcmd__help__subcmd__set"
                ;;
            hbctl__subcmd__help,attachment)
                cmd="hbctl__subcmd__help__subcmd__attachment"
                ;;
            hbctl__subcmd__help,auth)
                cmd="hbctl__subcmd__help__subcmd__auth"
                ;;
            hbctl__subcmd__help,completions)
                cmd="hbctl__subcmd__help__subcmd__completions"
                ;;
            hbctl__subcmd__help,entity-types)
                cmd="hbctl__subcmd__help__subcmd__entity__subcmd__types"
                ;;
            hbctl__subcmd__help,export)
                cmd="hbctl__subcmd__help__subcmd__export"
                ;;
            hbctl__subcmd__help,field)
                cmd="hbctl__subcmd__help__subcmd__field"
                ;;
            hbctl__subcmd__help,help)
                cmd="hbctl__subcmd__help__subcmd__help"
                ;;
            hbctl__subcmd__help,item)
                cmd="hbctl__subcmd__help__subcmd__item"
                ;;
            hbctl__subcmd__help,man)
                cmd="hbctl__subcmd__help__subcmd__man"
                ;;
            hbctl__subcmd__help,search)
                cmd="hbctl__subcmd__help__subcmd__search"
                ;;
            hbctl__subcmd__help,status)
                cmd="hbctl__subcmd__help__subcmd__status"
                ;;
            hbctl__subcmd__help,tag)
                cmd="hbctl__subcmd__help__subcmd__tag"
                ;;
            hbctl__subcmd__help,update)
                cmd="hbctl__subcmd__help__subcmd__update"
                ;;
            hbctl__subcmd__help__subcmd__attachment,delete)
                cmd="hbctl__subcmd__help__subcmd__attachment__subcmd__delete"
                ;;
            hbctl__subcmd__help__subcmd__attachment,download)
                cmd="hbctl__subcmd__help__subcmd__attachment__subcmd__download"
                ;;
            hbctl__subcmd__help__subcmd__attachment,list)
                cmd="hbctl__subcmd__help__subcmd__attachment__subcmd__list"
                ;;
            hbctl__subcmd__help__subcmd__attachment,upload)
                cmd="hbctl__subcmd__help__subcmd__attachment__subcmd__upload"
                ;;
            hbctl__subcmd__help__subcmd__auth,login)
                cmd="hbctl__subcmd__help__subcmd__auth__subcmd__login"
                ;;
            hbctl__subcmd__help__subcmd__auth,logout)
                cmd="hbctl__subcmd__help__subcmd__auth__subcmd__logout"
                ;;
            hbctl__subcmd__help__subcmd__auth,refresh)
                cmd="hbctl__subcmd__help__subcmd__auth__subcmd__refresh"
                ;;
            hbctl__subcmd__help__subcmd__auth,status)
                cmd="hbctl__subcmd__help__subcmd__auth__subcmd__status"
                ;;
            hbctl__subcmd__help__subcmd__entity__subcmd__types,create)
                cmd="hbctl__subcmd__help__subcmd__entity__subcmd__types__subcmd__create"
                ;;
            hbctl__subcmd__help__subcmd__entity__subcmd__types,delete)
                cmd="hbctl__subcmd__help__subcmd__entity__subcmd__types__subcmd__delete"
                ;;
            hbctl__subcmd__help__subcmd__entity__subcmd__types,list)
                cmd="hbctl__subcmd__help__subcmd__entity__subcmd__types__subcmd__list"
                ;;
            hbctl__subcmd__help__subcmd__field,delete)
                cmd="hbctl__subcmd__help__subcmd__field__subcmd__delete"
                ;;
            hbctl__subcmd__help__subcmd__field,get)
                cmd="hbctl__subcmd__help__subcmd__field__subcmd__get"
                ;;
            hbctl__subcmd__help__subcmd__field,list)
                cmd="hbctl__subcmd__help__subcmd__field__subcmd__list"
                ;;
            hbctl__subcmd__help__subcmd__field,set)
                cmd="hbctl__subcmd__help__subcmd__field__subcmd__set"
                ;;
            hbctl__subcmd__help__subcmd__item,create)
                cmd="hbctl__subcmd__help__subcmd__item__subcmd__create"
                ;;
            hbctl__subcmd__help__subcmd__item,dedup)
                cmd="hbctl__subcmd__help__subcmd__item__subcmd__dedup"
                ;;
            hbctl__subcmd__help__subcmd__item,delete)
                cmd="hbctl__subcmd__help__subcmd__item__subcmd__delete"
                ;;
            hbctl__subcmd__help__subcmd__item,get)
                cmd="hbctl__subcmd__help__subcmd__item__subcmd__get"
                ;;
            hbctl__subcmd__help__subcmd__item,import)
                cmd="hbctl__subcmd__help__subcmd__item__subcmd__import"
                ;;
            hbctl__subcmd__help__subcmd__item,list)
                cmd="hbctl__subcmd__help__subcmd__item__subcmd__list"
                ;;
            hbctl__subcmd__help__subcmd__item,move)
                cmd="hbctl__subcmd__help__subcmd__item__subcmd__move"
                ;;
            hbctl__subcmd__help__subcmd__item,tree)
                cmd="hbctl__subcmd__help__subcmd__item__subcmd__tree"
                ;;
            hbctl__subcmd__help__subcmd__item,update)
                cmd="hbctl__subcmd__help__subcmd__item__subcmd__update"
                ;;
            hbctl__subcmd__help__subcmd__item,upsert)
                cmd="hbctl__subcmd__help__subcmd__item__subcmd__upsert"
                ;;
            hbctl__subcmd__help__subcmd__tag,create)
                cmd="hbctl__subcmd__help__subcmd__tag__subcmd__create"
                ;;
            hbctl__subcmd__help__subcmd__tag,delete)
                cmd="hbctl__subcmd__help__subcmd__tag__subcmd__delete"
                ;;
            hbctl__subcmd__help__subcmd__tag,list)
                cmd="hbctl__subcmd__help__subcmd__tag__subcmd__list"
                ;;
            hbctl__subcmd__help__subcmd__tag,update)
                cmd="hbctl__subcmd__help__subcmd__tag__subcmd__update"
                ;;
            hbctl__subcmd__item,create)
                cmd="hbctl__subcmd__item__subcmd__create"
                ;;
            hbctl__subcmd__item,dedup)
                cmd="hbctl__subcmd__item__subcmd__dedup"
                ;;
            hbctl__subcmd__item,delete)
                cmd="hbctl__subcmd__item__subcmd__delete"
                ;;
            hbctl__subcmd__item,get)
                cmd="hbctl__subcmd__item__subcmd__get"
                ;;
            hbctl__subcmd__item,help)
                cmd="hbctl__subcmd__item__subcmd__help"
                ;;
            hbctl__subcmd__item,import)
                cmd="hbctl__subcmd__item__subcmd__import"
                ;;
            hbctl__subcmd__item,list)
                cmd="hbctl__subcmd__item__subcmd__list"
                ;;
            hbctl__subcmd__item,move)
                cmd="hbctl__subcmd__item__subcmd__move"
                ;;
            hbctl__subcmd__item,tree)
                cmd="hbctl__subcmd__item__subcmd__tree"
                ;;
            hbctl__subcmd__item,update)
                cmd="hbctl__subcmd__item__subcmd__update"
                ;;
            hbctl__subcmd__item,upsert)
                cmd="hbctl__subcmd__item__subcmd__upsert"
                ;;
            hbctl__subcmd__item__subcmd__help,create)
                cmd="hbctl__subcmd__item__subcmd__help__subcmd__create"
                ;;
            hbctl__subcmd__item__subcmd__help,dedup)
                cmd="hbctl__subcmd__item__subcmd__help__subcmd__dedup"
                ;;
            hbctl__subcmd__item__subcmd__help,delete)
                cmd="hbctl__subcmd__item__subcmd__help__subcmd__delete"
                ;;
            hbctl__subcmd__item__subcmd__help,get)
                cmd="hbctl__subcmd__item__subcmd__help__subcmd__get"
                ;;
            hbctl__subcmd__item__subcmd__help,help)
                cmd="hbctl__subcmd__item__subcmd__help__subcmd__help"
                ;;
            hbctl__subcmd__item__subcmd__help,import)
                cmd="hbctl__subcmd__item__subcmd__help__subcmd__import"
                ;;
            hbctl__subcmd__item__subcmd__help,list)
                cmd="hbctl__subcmd__item__subcmd__help__subcmd__list"
                ;;
            hbctl__subcmd__item__subcmd__help,move)
                cmd="hbctl__subcmd__item__subcmd__help__subcmd__move"
                ;;
            hbctl__subcmd__item__subcmd__help,tree)
                cmd="hbctl__subcmd__item__subcmd__help__subcmd__tree"
                ;;
            hbctl__subcmd__item__subcmd__help,update)
                cmd="hbctl__subcmd__item__subcmd__help__subcmd__update"
                ;;
            hbctl__subcmd__item__subcmd__help,upsert)
                cmd="hbctl__subcmd__item__subcmd__help__subcmd__upsert"
                ;;
            hbctl__subcmd__tag,create)
                cmd="hbctl__subcmd__tag__subcmd__create"
                ;;
            hbctl__subcmd__tag,delete)
                cmd="hbctl__subcmd__tag__subcmd__delete"
                ;;
            hbctl__subcmd__tag,help)
                cmd="hbctl__subcmd__tag__subcmd__help"
                ;;
            hbctl__subcmd__tag,list)
                cmd="hbctl__subcmd__tag__subcmd__list"
                ;;
            hbctl__subcmd__tag,update)
                cmd="hbctl__subcmd__tag__subcmd__update"
                ;;
            hbctl__subcmd__tag__subcmd__help,create)
                cmd="hbctl__subcmd__tag__subcmd__help__subcmd__create"
                ;;
            hbctl__subcmd__tag__subcmd__help,delete)
                cmd="hbctl__subcmd__tag__subcmd__help__subcmd__delete"
                ;;
            hbctl__subcmd__tag__subcmd__help,help)
                cmd="hbctl__subcmd__tag__subcmd__help__subcmd__help"
                ;;
            hbctl__subcmd__tag__subcmd__help,list)
                cmd="hbctl__subcmd__tag__subcmd__help__subcmd__list"
                ;;
            hbctl__subcmd__tag__subcmd__help,update)
                cmd="hbctl__subcmd__tag__subcmd__help__subcmd__update"
                ;;
            *)
                ;;
        esac
    done

    case "${cmd}" in
        hbctl)
            opts="-q -C -P -h -V --url --api-key --output --json --select --dry-run --quiet --config --profile --help --version auth item attachment search field tag entity-types entity-type status export completions man update self-update help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 1 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__attachment)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help upload list download delete help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__attachment__subcmd__delete)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__attachment__subcmd__download)
            opts="-q -C -P -h --all --all-items --tag --items-from --mime --ext --out --overwrite --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tag)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --items-from)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --mime)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --ext)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --out)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__attachment__subcmd__help)
            opts="upload list download delete help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__attachment__subcmd__help__subcmd__delete)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__attachment__subcmd__help__subcmd__download)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__attachment__subcmd__help__subcmd__help)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__attachment__subcmd__help__subcmd__list)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__attachment__subcmd__help__subcmd__upload)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__attachment__subcmd__list)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__attachment__subcmd__upload)
            opts="-q -C -P -h --name --skip-existing --overwrite --force --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --name)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__auth)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help login status logout refresh help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__auth__subcmd__help)
            opts="login status logout refresh help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__auth__subcmd__help__subcmd__help)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__auth__subcmd__help__subcmd__login)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__auth__subcmd__help__subcmd__logout)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__auth__subcmd__help__subcmd__refresh)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__auth__subcmd__help__subcmd__status)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__auth__subcmd__login)
            opts="-u -q -C -P -h --with-token --username --password-stdin --insecure-storage --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --username)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -u)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__auth__subcmd__logout)
            opts="-q -C -P -h --insecure-storage --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__auth__subcmd__refresh)
            opts="-q -C -P -h --insecure-storage --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__auth__subcmd__status)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__completions)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help bash elvish fish powershell zsh"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__entity__subcmd__types)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help list create delete help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__entity__subcmd__types__subcmd__create)
            opts="-q -C -P -h --description --is-location --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --description)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__entity__subcmd__types__subcmd__delete)
            opts="-q -C -P -h --force --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__entity__subcmd__types__subcmd__help)
            opts="list create delete help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__entity__subcmd__types__subcmd__help__subcmd__create)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__entity__subcmd__types__subcmd__help__subcmd__delete)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__entity__subcmd__types__subcmd__help__subcmd__help)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__entity__subcmd__types__subcmd__help__subcmd__list)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__entity__subcmd__types__subcmd__list)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__export)
            opts="-q -C -P -h --tag --has-field --field --sort --format --columns --align --empty --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tag)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --has-field)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --field)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --sort)
                    COMPREPLY=($(compgen -W "name id" -- "${cur}"))
                    return 0
                    ;;
                --format)
                    COMPREPLY=($(compgen -W "json csv markdown" -- "${cur}"))
                    return 0
                    ;;
                --columns)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --align)
                    COMPREPLY=($(compgen -W "default left right center" -- "${cur}"))
                    return 0
                    ;;
                --empty)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__field)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help list get set delete help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__field__subcmd__delete)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__field__subcmd__get)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__field__subcmd__help)
            opts="list get set delete help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__field__subcmd__help__subcmd__delete)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__field__subcmd__help__subcmd__get)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__field__subcmd__help__subcmd__help)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__field__subcmd__help__subcmd__list)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__field__subcmd__help__subcmd__set)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__field__subcmd__list)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__field__subcmd__set)
            opts="-q -C -P -h --type --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --type)
                    COMPREPLY=($(compgen -W "text number boolean" -- "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help)
            opts="auth item attachment search field tag entity-types status export completions man update help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__attachment)
            opts="upload list download delete"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__attachment__subcmd__delete)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__attachment__subcmd__download)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__attachment__subcmd__list)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__attachment__subcmd__upload)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__auth)
            opts="login status logout refresh"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__auth__subcmd__login)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__auth__subcmd__logout)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__auth__subcmd__refresh)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__auth__subcmd__status)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__completions)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__entity__subcmd__types)
            opts="list create delete"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__entity__subcmd__types__subcmd__create)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__entity__subcmd__types__subcmd__delete)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__entity__subcmd__types__subcmd__list)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__export)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__field)
            opts="list get set delete"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__field__subcmd__delete)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__field__subcmd__get)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__field__subcmd__list)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__field__subcmd__set)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__help)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__item)
            opts="list get create update upsert delete import dedup move tree"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__item__subcmd__create)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__item__subcmd__dedup)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__item__subcmd__delete)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__item__subcmd__get)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__item__subcmd__import)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__item__subcmd__list)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__item__subcmd__move)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__item__subcmd__tree)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__item__subcmd__update)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__item__subcmd__upsert)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__man)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__search)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__status)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__tag)
            opts="list create update delete"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__tag__subcmd__create)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__tag__subcmd__delete)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__tag__subcmd__list)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__tag__subcmd__update)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__help__subcmd__update)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help list get create update upsert delete import dedup move tree help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__create)
            opts="-q -C -P -h --name --description --type --parent --tag --manufacturer --model --serial --notes --quantity --purchase-price --purchase-date --purchase-from --field --field-type --from-json --attach --force --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --name)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --description)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --type)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --parent)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --tag)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --manufacturer)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --model)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --serial)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --notes)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --quantity)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --purchase-price)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --purchase-date)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --purchase-from)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --field)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --field-type)
                    COMPREPLY=($(compgen -W "text number boolean" -- "${cur}"))
                    return 0
                    ;;
                --from-json)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --attach)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__dedup)
            opts="-q -C -P -h --threshold --delete --merge --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --threshold)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__delete)
            opts="-q -C -P -h --force --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__get)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__help)
            opts="list get create update upsert delete import dedup move tree help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__help__subcmd__create)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__help__subcmd__dedup)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__help__subcmd__delete)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__help__subcmd__get)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__help__subcmd__help)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__help__subcmd__import)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__help__subcmd__list)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__help__subcmd__move)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__help__subcmd__tree)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__help__subcmd__update)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__help__subcmd__upsert)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__import)
            opts="-q -C -P -h --format --skip-existing --update-existing --fill-missing --match-by --parent --attach --force --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --format)
                    COMPREPLY=($(compgen -W "json csv" -- "${cur}"))
                    return 0
                    ;;
                --match-by)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --parent)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --attach)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__list)
            opts="-q -C -P -h --tag --type --parent --has-field --page-size --all --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tag)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --type)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --parent)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --has-field)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --page-size)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__move)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__tree)
            opts="-q -C -P -h --root --max-depth --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --root)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --max-depth)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__update)
            opts="-q -C -P -h --name --description --type --parent --tag --add-tag --remove-tag --manufacturer --model --serial --quantity --purchase-price --purchase-date --purchase-from --notes --field --field-type --from-json --fill-missing --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --name)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --description)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --type)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --parent)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --tag)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --add-tag)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --remove-tag)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --manufacturer)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --model)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --serial)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --quantity)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --purchase-price)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --purchase-date)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --purchase-from)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --notes)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --field)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --field-type)
                    COMPREPLY=($(compgen -W "text number boolean" -- "${cur}"))
                    return 0
                    ;;
                --from-json)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__item__subcmd__upsert)
            opts="-q -C -P -h --name --description --type --parent --tag --manufacturer --model --serial --notes --quantity --purchase-price --purchase-date --purchase-from --field --field-type --fill-missing --from-json --match-by --attach --force --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --name)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --description)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --type)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --parent)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --tag)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --manufacturer)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --model)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --serial)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --notes)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --quantity)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --purchase-price)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --purchase-date)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --purchase-from)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --field)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --field-type)
                    COMPREPLY=($(compgen -W "text number boolean" -- "${cur}"))
                    return 0
                    ;;
                --from-json)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --match-by)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --attach)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__man)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__search)
            opts="-q -C -P -h --tag --model --serial --manufacturer --field --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --tag)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --model)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --serial)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --manufacturer)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --field)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__status)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__tag)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help list create update delete help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__tag__subcmd__create)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__tag__subcmd__delete)
            opts="-q -C -P -h --force --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__tag__subcmd__help)
            opts="list create update delete help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__tag__subcmd__help__subcmd__create)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__tag__subcmd__help__subcmd__delete)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__tag__subcmd__help__subcmd__help)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__tag__subcmd__help__subcmd__list)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__tag__subcmd__help__subcmd__update)
            opts=""
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__tag__subcmd__list)
            opts="-q -C -P -h --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__tag__subcmd__update)
            opts="-q -C -P -h --name --description --color --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --name)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --description)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --color)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        hbctl__subcmd__update)
            opts="-y -q -C -P -h --check --yes --version --url --api-key --output --json --select --dry-run --quiet --config --profile --help"
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]] ; then
                COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                return 0
            fi
            case "${prev}" in
                --version)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --url)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --api-key)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --output)
                    COMPREPLY=($(compgen -W "table json plain" -- "${cur}"))
                    return 0
                    ;;
                --select)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --config)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -C)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --profile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                -P)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
    esac
}

if [[ "${BASH_VERSINFO[0]}" -eq 4 && "${BASH_VERSINFO[1]}" -ge 4 || "${BASH_VERSINFO[0]}" -gt 4 ]]; then
    complete -F _hbctl -o nosort -o bashdefault -o default hbctl
else
    complete -F _hbctl -o bashdefault -o default hbctl
fi
