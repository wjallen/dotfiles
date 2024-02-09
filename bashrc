
alias more="less"
alias mroe="less"
#alias dc="cd"
#alias ls="ls -F --color=none"
alias l="ls -l --color=auto"
alias ls="ls -F --color=auto"
alias ll="ls -l --color=auto"
alias lla="ls -la --color=auto"

function c {
  curl cheat.sh/$1
}

# archive data to ranch (cronjob on staff.ls6)
# cds
# for DIR in ` \ls $WORK `; do tar -czf ${DIR}.tar.gz /work/03439/wallen/${DIR}; done
# rsync -azv --size-only --stats *.tar.gz wallen@${ARCHIVER}:${ARCHIVE}
# rsync -azv --size-only --stats *.tar.gz wallen@${ARCHIVER}:${ARCHIVE}
# for DIR in ` \ls $WORK `; do rm ${DIR}.tar.gz; done
export FORPUS_ARCHIVE="wallen@ranch.tacc.utexas.edu:/stornext/ranch_01/ranch/projects/DBS22003/"

# Check status/availability of queues
# sinfo -o "%20P %5a %.10l %16F"

# Check package information
# rpm -qa | grep package_name
# rpm -qip /admin/build/rpms/RPMS/x86_64/full_package_name.rpm   (as root)

# Recursively find newest file in a directory
# find $DIR -type f -exec stat --format '%Y :%y %n' "{}" \; | sort -nr | cut -d: -f2- | head


# Added by cryoSPARC:
#export PATH="/work/03439/wallen/ls6/apps/cryosparc_master/bin":$PATH
export PATH="/work/03439/wallen/ls6/apps/firefox/":$PATH

