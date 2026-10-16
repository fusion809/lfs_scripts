#!/bin/bash
awk "
/^MemTotal:/ { total = \$2 }
/^MemFree:/  { free = \$2 }
END {
    if (total > 0) {
        printf \"%.0f%%\n\", (100 * (total - free) / total)
    } else {
        print \"0%\"
    }
}" /proc/meminfo
