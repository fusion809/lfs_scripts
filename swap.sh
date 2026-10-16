#!/bin/bash
awk "
/^SwapTotal:/ { total = \$2 }
/^SwapFree:/  { free = \$2 }
END {
    if (total > 0) {
        printf \"%.0f%%\n\", (100 * (total - free) / total)
    } else {
        print \"0%\"
    }
}" /proc/meminfo
