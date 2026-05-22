#!/usr/bin/env bash
# chain_stats.sh - Compute alignment statistics from a liftOver chain file.
#
# Usage:
#   chain_stats.sh <chain.gz> <source.sizes> <target.sizes>
#
# Arguments:
#   chain.gz        liftOver chain file (gzipped). source = tName, target = qName.
#   source.sizes    chrom.sizes for the assembly being lifted FROM (tName)
#   target.sizes    chrom.sizes for the assembly being lifted TO   (qName)
#
# Output:
#   Writes <prefix>.chain.stats.tsv to the current directory.
#
# Metrics:
#   aligned_bases        Sum of all gapless block lengths.
#                        Exact source coverage (net-filtered blocks do not
#                        overlap on the source side); approximate target
#                        coverage (blocks may overlap on the target side).
#   source_span          Sum of chain envelope widths on source (includes gaps).
#   target_span          Sum of chain envelope widths on target (includes gaps).
#   source_pct_covered   aligned_bases / source_total_bases * 100
#   approx_target_pct_covered   aligned_bases / target_total_bases * 100

set -euo pipefail

die() { echo "Error: $*" >&2; exit 1; }

usage() {
    grep '^#' "$0" | sed 's/^# \?//' | sed -n '2,/^$/p' >&2
    exit 1
}

[[ $# -ne 3 ]] && usage

CHAIN="$1"
SOURCE_SIZES="$2"
TARGET_SIZES="$3"

[[ -f "$CHAIN"        ]] || die "chain file not found: $CHAIN"
[[ -f "$SOURCE_SIZES" ]] || die "source sizes not found: $SOURCE_SIZES"
[[ -f "$TARGET_SIZES" ]] || die "target sizes not found: $TARGET_SIZES"

PREFIX=$(basename "$CHAIN"); PREFIX="${PREFIX%.gz}"; PREFIX="${PREFIX%.chain}"
OUT="${PREFIX}.chain.stats.tsv"

# ---------------------------------------------------------------------------
# Compute genome totals from sizes files
# ---------------------------------------------------------------------------
source_total=$(awk '{sum += $2} END {printf "%d", sum}' "$SOURCE_SIZES")
target_total=$(awk '{sum += $2} END {printf "%d", sum}' "$TARGET_SIZES")

[[ "$source_total" -gt 0 ]] || die "source sizes file is empty or malformed: $SOURCE_SIZES"
[[ "$target_total" -gt 0 ]] || die "target sizes file is empty or malformed: $TARGET_SIZES"

# ---------------------------------------------------------------------------
# Single awk pass over the chain file
#
# Chain header fields:
#   $1=chain $2=score $3=tName $4=tSize $5=tStrand $6=tStart $7=tEnd
#   $8=qName $9=qSize $10=qStrand $11=qStart $12=qEnd $13=id
#
# Block lines:
#   3 fields: size dt dq  (gapless block followed by gaps on each side)
#   1 field:  size        (last block in a chain, no trailing gaps)
# ---------------------------------------------------------------------------
zcat "$CHAIN" | awk \
    -v chain_file="$CHAIN" \
    -v source_total="$source_total" \
    -v target_total="$target_total" '
/^chain / {
    chains++
    source_span += $7  - $6
    target_span += $12 - $11
    source_chroms[$3] = 1
    target_chroms[$8] = 1
}
/^[0-9]/ {
    aligned_bases += $1
}
END {
    source_pct = 100.0 * aligned_bases / source_total
    target_pct = 100.0 * aligned_bases / target_total

    printf "chain_file\t%s\n",             chain_file
    printf "chains\t%d\n",                 chains
    printf "aligned_bases\t%d\n",          aligned_bases
    printf "source_span\t%d\n",            source_span
    printf "target_span\t%d\n",            target_span
    printf "source_chrom_count\t%d\n",     length(source_chroms)
    printf "target_chrom_count\t%d\n",     length(target_chroms)
    printf "source_total_bases\t%d\n",     source_total
    printf "target_total_bases\t%d\n",     target_total
    printf "source_pct_covered\t%.3f\n",   source_pct
    printf "approx_target_pct_covered\t%.3f\n",   target_pct
}' > "$OUT"
