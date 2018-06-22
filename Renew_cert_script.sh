#!/bin/bash
user='your cpanel username here'
pass="you cpanel password here"
email='an email address under your domain'

HOME=/home/$user                         # change 'user' to your username
mydir=$HOME/letsacme                     # this directory path
chlng=$HOME/challenge/acme-challenge    # challenge directory path
letsacme_log="$mydir"/letsacme.log       # path to letsacme log file

acc_key="$mydir"/account.key             # path to account key file
key="$mydir"/dom.key                     # path to key file that was used to create CSR
csr="$mydir"/dom.csr                     # path to CSR file
dom_crt="$mydir"/dom.crt                 # path to cert file
chain_crt="$mydir"/chain.crt             # path to chain file
full_crt="$mydir"/fullchain.crt          # path to fullchain file
dom_file="$mydir"/dom.list               # path to a file containing domain names per line

letsacme="$mydir"/letsacme.py            # path to letsacme.py
sslic="$mydir"/sslic.php                 # path to sslic.php

# max try depends on how often you will run this script.
max_try=20 # don't change it unless you know what you are doing

#######################################################################
# Everything below this are CRITICAL do not edit any unless you know what you are doing ;)
#######################################################################

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

test=false

if $test; then
    test_flag=--test
else
    test_flag=
fi

print_err(){
    echo "$@" >>/dev/stderr
}

print_out(){
    echo "$@" >>/dev/stdout
}
print_out "### Logs for renewcert script ###"

count=0
st="$(date -u)"

# init log file. Log files will always contain current logs
echo '### Logs for letsacme script ###' > "$letsacme_log"

while true;do
    count=$(expr $count + 1)
    if [ $count -gt $max_try ]; then
        # Failed
        msg="Failed to renrew certificate ($dom_crt) from $st to $(date -u)"
        sub="Failed to renrew certificate"
        echo "$msg" | mail -s "$sub" $email
        print_err "$msg"
        exit 1
    fi
    if python "$letsacme" \
        --account-key "$acc_key" \
        --csr "$csr" \
        --acme-dir "$chlng" \
        --cert-file "$dom_crt.tmp" \
        --chain-file "$chain_crt.tmp" $test_flag \
        > "$full_crt.tmp" \
        2>> "$letsacme_log"
    then
        cp "$dom_crt.tmp" "$dom_crt"
        cp "$chain_crt.tmp" "$chain_crt"
        cp "$full_crt.tmp" "$full_crt"
        # send an email
        msg="Successfully renewed certificate ($dom_crt) @ $(date -u)"
        sub="Renewed SSL certificate"
        echo "$msg" | mail -s "$sub" $email
        # log the success msg
        print_out "$msg"
        # install the certificate

        doms="$(sed -e '/^[[:blank:]]*$/d' \
            -e 's/^[[:blank:]]*//' \
            -e '/^[[:blank:]]*www\..*$/d' "$dom_file")"
        for dom in $doms; do
            USER="$user" PASS="$pass" EMAIL="$email" php "$sslic" "$dom" "$dom_crt" "$key" "$chain_crt"
            sleep 5
        done
        break
    else
        sleep `tr -cd 0-9 </dev/urandom | head -c 4`
        # sleep for max 9999 seconds, then try again
        print_err "Retry triggered at $(date -u)"
    fi
done
