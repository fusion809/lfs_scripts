function Reval {
	R -q -e "$@" | grep "\[1\] " | cut -d ' ' -f 2
}

function plot {
	systemd-analyze plot > $HOME/plots/$timestamp.svg
}

function shplot {
	if [[ -n $1 ]] && [[ $1 != "1" ]]; then
		file=$HOME/plots/"$(ls $HOME/plots | grep -v "$timestamp" | tail -n "$1" | head -n 1)"
	else
		file="$HOME/plots/$timestamp.svg"
	fi
	eog "$file"
}

alias show_plot=shplot

function boot_times {
	cat ~/plots/*.svg \
| grep kernel \
| grep user \
| sed 's/.*= //g' \
| sort -n
}

alias bts=boot_times

function boot_time {
	if [[ -f ~/plots/$timestamp.svg ]]; then
		filename=$HOME/plots/$timestamp.svg
	else
		filename=$HOME/plots/outliers/$timestamp.svg
	fi
	cat $filename \
| grep kernel \
| grep user \
| sed 's/.*= //g'
}

alias bt=boot_time

function avg_boot_time {
	boot_times | awk '{sum+=$1; n++} END {if(n>0) print sum/n}'
}

alias avgbt=avg_boot_time
alias avg_bt=avg_boot_time

function med_boot_time {
	boot_times \
| awk '
{
    a[NR]=$1
}
END {
    if (NR % 2 == 1)
        print a[(NR+1)/2]
    else
        print (a[NR/2] + a[NR/2+1]) / 2
}'
}

alias medbt=med_boot_time
alias med_bt=med_boot_time

function sd_boot_time {
	grep kernel ~/plots/*.svg \
| grep user \
| sed 's/.*= //g' \
| awk '
{
    n++
    sum += $1
    sumsq += $1 * $1
}
END {
    mean = sum / n
    samp_sd = sqrt((sumsq - n * mean * mean) / (n - 1))

    if (n > 1)
        print samp_sd
}'
}

alias sdbt=sd_boot_time

function iqr_boot_time {
	grep kernel ~/plots/*.svg \
| grep user \
| sed 's/.*= //g' \
| sort -n \
| awk '
{
    a[NR] = $1
}
END {
    n = NR

    # Median helper
    mid = int((n + 1) / 2)

    # Q1 position
    q1_pos = int((n + 1) * 0.25)
    if (q1_pos < 1) q1_pos = 1

    # Q3 position
    q3_pos = int((n + 1) * 0.75)
    if (q3_pos < 1) q3_pos = 1

    q1 = a[q1_pos]
    q3 = a[q3_pos]

    print q3 - q1
}'
}

alias ibt=iqr_boot_time

function stat_boot_time {
	grep kernel ~/plots/*.svg \
| grep user \
| sed 's/.*= //g' \
| sort -n \
| awk '
{
    a[NR]=$1
    sum+=$1
    sumsq+=$1*$1
}
END {
    n=NR
    mean=sum/n

    # Median
    if (n%2)
        median=a[(n+1)/2]
    else
        median=(a[n/2]+a[n/2+1])/2

    # Quartiles (simple method)
    q1=a[int((n+1)*0.25)]
    q3=a[int((n+1)*0.75)]
    iqr=q3-q1

    # Standard deviations
    samp_sd=(n>1)?sqrt((sumsq-n*mean*mean)/(n-1)):"NA"

    print "Count:", n
    print "Mean:", mean
    print "Median:", median
    print "Q1:", q1
    print "Q3:", q3
    print "IQR:", iqr
    print "Sample SD:", samp_sd
}'
}

alias sbt=stat_boot_time

function plot_boot_times {
	grep kernel ~/plots/*.svg \
| grep user \
| sed 's/.*= //g' \
> ~/lfs-scripts/boots.dat
	sed -e "s|Linux From Scratch|$(os-release)|g" \
		-e "s|boot time distribution|boot time distribution as of ${timestamp}.|g" ~/lfs-scripts/hist.gnuplot > ~/lfs-scripts/hist.tmp.gnuplot
	gnuplot ~/lfs-scripts/hist.tmp.gnuplot
	rm ~/lfs-scripts/hist.tmp.gnuplot
	if [[ $XDG_CURRENT_DESKTOP == "KDE" ]]; then
		IMAGE_EDITOR=gwenview
	elif [[ $XDG_CURRENT_DESKTOP == "GNOME" ]]; then
		IMAGE_EDITOR=eog
	fi
	$IMAGE_EDITOR ~/lfs-scripts/boots_hist.png
}

alias pbts=plot_boot_times


function mvOutliers {
R --vanilla -q <<'EOF'

# Define directory explicitly
plot_dir <- path.expand("~/plots")

# Get full file paths
files <- list.files(plot_dir, pattern="\\.svg$", full.names=TRUE)

# Function to extract boot time
get_time <- function(f) {
  lines <- readLines(f, warn = FALSE)

  line <- lines[grepl("Startup finished in", lines)]

  if (length(line) == 0) return(NA_real_)

  # Extract the final total time after '='
  val <- sub(".*= ([0-9.]+)s.*", "\\1", line)

  as.numeric(val)
}
times <- sapply(files, get_time)

# Remove NAs
valid <- !is.na(times)
files <- files[valid]
times <- times[valid]

# Statistics
median_x <- median(times)
iqr_x <- IQR(times)

fac <- 2.5
lower <- median_x - fac*iqr_x
upper <- median_x + fac*iqr_x

cat("n =", length(times), "\n")
cat("median =", median_x, "\n")
cat("IQR =", iqr_x, "\n")
cat("lower bound =", lower, "\n")
cat("upper bound =", upper, "\n")

# Identify outliers
outlier_idx <- which(times < lower | times > upper)
outlier_files <- files[outlier_idx]

cat("\nOutlier files:\n")
print(outlier_files)

# Create outliers directory inside ~/plots
out_dir <- file.path(plot_dir, "outliers")
dir.create(out_dir, showWarnings = FALSE)

# Move files
file.rename(outlier_files,
            file.path(out_dir, basename(outlier_files)))

cat("\nMoved", length(outlier_files), "files to", out_dir, "\n")

EOF
}

read uptime_seconds _ < /proc/uptime

if (( uptime_seconds <= 5 )); then
	mvOutliers
fi

