#!/usr/bin/env bash
set -Eeuo pipefail

registry="127.0.0.1:5000"
keep=${REGISTLER_KEEP:-3}
workingdir="/tmp/registler"

function _err() {
  echo "err: $*"
  sleep 1
}

while true; do
  started_at=$SECONDS

  if ! repositories=$(regctl repo ls $registry); then
    _err "regctl repo ls $registry"
    continue
  fi

  for repository in $repositories; do
    rm -rf "$workingdir" || true
    mkdir -p $workingdir

    echo "repository: $repository"
    if ! tags=$(regctl tag ls "$registry/$repository"); then
      _err "regctl tag ls $registry/$repository"
      continue
    fi

    for tag in $tags; do
      case "$tag" in
        cache|latest)
          continue
        ;;
      esac

      if ! timestamp=$(regctl image config "$registry/$repository:$tag" | jq -r '.created'); then
        _err "regctl image config failed"
        continue
      fi

      echo "$tag" > "$workingdir/$repository-$timestamp-$tag"
    done

    if ! timestamps=$(2>/dev/null ls $workingdir/*); then
      continue
    fi

    if ! lines=$(echo "$timestamps" | wc -l | tr -d ' '); then
      _err "counting lines failed"
      continue
    fi

    lines_delete=$((lines - keep))
    if [[ "$lines_delete" -le 0 ]]; then
      continue
    fi

    timestamps_to_delete=$(echo "$timestamps" | head -$lines_delete)

    for timestamp in $timestamps_to_delete; do
      if ! tag_to_delete=$(cat "$timestamp"); then
        _err "failed to read $timestamp"
        continue
      fi

      if ! regctl tag rm "$registry/$repository:$tag_to_delete"; then
        _err "regctl tag rm $registry/$repository:$tag_to_delete"
        continue
      fi

      echo "deleted $registry/$repository:$tag_to_delete"
    done
  done

  took=$((SECONDS - started_at))
  remaining=$((3600 - took))
  if [[ "$remaining" -le 0 ]]; then
    remaining=1
  fi

  echo "next iteration in ${remaining}s"
  sleep $remaining
done
