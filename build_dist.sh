#!/usr/bin/env bash

set -u
set -e

source "_functions"
source "_vars"

if [ "$DEBUG_SCRIPT" = 1 ]; then
    set -x
fi

_init_type() {
    [ ! -e "$DIR_TMP" ] || rm -rf "$DIR_TMP"
    if [ -e "$DIR_TMP" ]; then
        _trace "It was error when delete tmp dir: '$DIR_TMP'"
        exit 1
    fi
    mkdir -p "$DIR_TMP_DOCKERIZE"

    DIR_DIST_TYPE="$DIR_DIST/$TYPE"
    DIR_BACKUP_TYPE="$DIR_BACKUP/$TYPE"
    [ -d "$DIR_DIST_TYPE" ]   || mkdir -p "$DIR_DIST_TYPE"
#    [ -d "$DIR_BACKUP_TYPE" ] || mkdir -p "$DIR_BACKUP_TYPE"
}

_set_dockerize_dir_level() {
    CURRENT_LEVEL="$1"
    CURRENT_LEVEL="${CURRENT_LEVEL%/}"
    CURRENT_LEVEL="${CURRENT_LEVEL#/}"
    [ -z "$CURRENT_LEVEL" ] || CURRENT_LEVEL="/$CURRENT_LEVEL"
}

_create_header_yml() {
    cat "$DIR_TEMPLATE_ENVS/$HEADER_YML"   > "$DIR_TMP_DOCKERIZE/$MAIN_YML"
}

_create_footer_yml() {
    echo                                  >> "$DIR_TMP_DOCKERIZE/$MAIN_YML"
    cat "$DIR_TEMPLATE_ENVS/$FOOTER_YML"  >> "$DIR_TMP_DOCKERIZE/$MAIN_YML"
}

_create_main_yml() {
    _set_dockerize_dir_level "/$TYPE"
    _add_dockerize_files_from_level

    echo -e "\nservices:" >> "$DIR_TMP_DOCKERIZE/$MAIN_YML"
    for SERVICE in ${ENABLE_SERVICES[@]}; do

        _set_dockerize_dir_level "/$TYPE/$SERVICE"
        _add_dockerize_files_from_level "$SERVICE".env

        local YML="${DIR_TEMPLATE_ENVS}${CURRENT_LEVEL}/$SERVICE_YML"
        [ -e "$YML" ] || continue
        echo                                       >> "$DIR_TMP_DOCKERIZE/$MAIN_YML"
        echo -e "#Service: $SERVICE"               >> "$DIR_TMP_DOCKERIZE/$MAIN_YML"
        cat "$YML" | sed -re "s/^/$STRING_IDENT/g" >> "$DIR_TMP_DOCKERIZE/$MAIN_YML"
    done
}

_add_dockerize_env_file() {
    local fn=$1
    local dst=$2

    [ ! -e "$dst" ] && touch "$dst" || :

    local full_fn="${DIR_TEMPLATE_ENVS}${CURRENT_LEVEL}/$fn"
    [ ! -e "$full_fn" ] && return 0 || :

    echo                                   >> "$dst"
    _print_delimiter_line >> "$dst"
    echo -e "# File: ${CURRENT_LEVEL}/$fn" >> "$dst"
    _print_delimiter_line >> "$dst"
    cat "$full_fn"                         >> "$dst"
    echo                                   >> "$dst"
}

_copy_dockerize_dirs_from_level() {
    local src_dir
    local dst_dir

    for FOLDER in ${ADD_DOCKERIZE_DIR[@]}; do
        src_dir="$DIR_TEMPLATE_DOCKERIZE/$FOLDER$CURRENT_LEVEL"
        [ ! -d "$src_dir" ] && continue || :
        [ "$FOLDER" = "$DN_ROOT" ] && dst_dir="$DIR_TMP_DOCKERIZE" || dst_dir="$DIR_TMP_DOCKERIZE/$FOLDER"
        [ ! -d "$dst_dir" ] && mkdir -p "$dst_dir" || :
        _cp_files_from_dir "${src_dir}" "$dst_dir"
    done
}

_add_dockerize_files_from_level() {

    _copy_dockerize_dirs_from_level

    _add_dockerize_env_file "$FN_SRC_IMAGE_ENV"     "$DIR_TMP_DOCKERIZE/$FN_DST_IMAGE_ENV"
    _add_dockerize_env_file "$FN_SRC_CONTAINER_ENV" "$DIR_TMP_DOCKERIZE/$FN_DST_CONTAINER_ENV"

    local FN_SERVICE_ENV=${1:-}
    [ ! -z "$FN_SERVICE_ENV" ] || return 0
    _add_dockerize_env_file "$FN_SERVICE_ENV" "$DIR_TMP_DOCKERIZE/$FN_SERVICE_ENV"
}

_add_dockerize_services(){
    src="$DIR_TEMPLATE_SERVICES"
    dst="$DIR_TMP_DOCKERIZE/$DN_SERVICES"
    for SERVICE in ${ENABLE_SERVICES[@]}; do
        _cp_dir "$src/$SERVICE" "$dst" "-r"
    done
}

_save_dockerize() {
    if [ -d "$DIR_DIST_TYPE" ]; then 
        [ "$DO_BACKUP_DOCKERIZE" = 1 ] && _mv "$DIR_DIST_TYPE/$DN_DOCKERIZE" "$DIR_BACKUP_TYPE" || rm -rf "$DIR_DIST_TYPE/$DN_DOCKERIZE"
    fi
    _mv "$DIR_TMP_DOCKERIZE" "$DIR_DIST_TYPE"
}

_save_files() {
    local src
    local dst

    # backup
    if [ ${#FOLDERS_MV_BACKUP[@]} -gt 0 ]; then
        for FOLDER in ${FOLDERS_MV_BACKUP[@]}; do
            src="$DIR_DIST_TYPE/$FOLDER"
            dst="$DIR_BACKUP_TYPE"
            _mv "$src" "$dst"
        done
    fi

    if [ ${#FOLDERS_CP_BACKUP[@]} -gt 0 ]; then
        for FOLDER in ${FOLDERS_CP_BACKUP[@]}; do
            src="$DIR_DIST_TYPE/$FOLDER"
            dst="$DIR_BACKUP_TYPE/$FOLDER"
            _cp_dir "$src" "$dst" "-raT"
        done
    fi

    # new
    if [ ${#ADD_TO_DIST_FOLDERS[@]} -gt 0 ]; then
        for FOLDER in ${ADD_TO_DIST_FOLDERS[@]}; do
            src="$DIR_TEMPLATE/$FOLDER"
            dst="$DIR_DIST_TYPE/$FOLDER"
            _cp_dir "$src" "$dst" "-raT"
        done
    fi
}

_clean() {
    rm -d "$DIR_TMP"
}

_save_dist() {
    _save_dockerize
    _save_files
}

_prepare_dist() {
    for TYPE in ${AVAILABLE_TYPE[@]}; do
        _init_type

        _set_dockerize_dir_level "/"
        _add_dockerize_files_from_level
        _add_dockerize_services

        _create_header_yml
        _create_main_yml
        _create_footer_yml

        _save_dist
        _clean
    done
}


_clean_backup() {
    if [ -d "$DIR_BACKUP_ROOT" ]; then 
        [ $(find "$DIR_BACKUP_ROOT" | wc -l) -le 1 ] && rm -rf "$DIR_BACKUP_ROOT" || :
    fi
}

_prepare_dist
_clean_backup

exit 0