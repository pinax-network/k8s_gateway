#!/usr/bin/env bash

DOMAIN="foo.org"

# Define the routes/should work
read -r -d '' routes <<'EOF'
good.ok true
target.ok true
abcd0123456789012345678901234567890123456789012345678901234567890 false
foo_bar false
*.service-wildcard true
asdf.service-wildcard true

myservicea true
myserviceb true
*.myservice true
asdf.myservice true
wasd.myservice true
ingress.target true

virtualservera true
*.virtualserverb true
asdf.virtualserverb true

myservicea.gw true
myserviceb.gw true
myservicec.gw-wrong false
myserviced.gw true
myservice-cname.gw true
myservicetls.gw true
myservicegrpc.gw true
myservicegrpc-cname.gw true
*.http-wildcard.gw true
asdf.http-wildcard.gw true
*.tls-wildcard.gw true
asdf.tls-wildcard.gw true
*.grpc-wildcard.gw true
asdf.grpc-wildcard.gw true
EOF

# Define the certificates/should work
read -r -d '' certs <<'EOF'
challenge-myservicea true
challenge-myserviceb true
challenge-myservicec true
challenge-myserviced false
EOF

# ANSI color codes for output
GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m' # No Color

# Process each route from the list
echo "====================="
echo "Testing A DNS records"
echo "====================="
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Split the line into route and expected outcome
    route=$(echo "$line" | awk '{print $1}')
    expected=$(echo "$line" | awk '{print $2}')
    result=$(dig @172.17.0.2 -p 32553 +short "$route.$DOMAIN" 2>/dev/null)

    output="${result:+${result//$'\n'/, }}"
    output="${output:-null}"

    echo -n "Input: $route.$DOMAIN, Output: $output "

    if [[ -n "$result" && "$expected" == "true" ]]; then
        echo -e "[${GREEN}OK${NC}]"
    elif [[ -z "$result" && "$expected" == "false" ]]; then
        echo -e "[${GREEN}OK${NC}]"
    else
        echo -e "[${RED}ERROR${NC}]"
    fi
done <<<"$routes"

# Process each route from the list
echo "======================="
echo "Testing TXT DNS records"
echo "======================="
# Process each certs from the list
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Split the line into route and expected outcome
    route=$(echo "$line" | awk '{print $1}')
    expected=$(echo "$line" | awk '{print $2}')
    result=$(dig @172.17.0.2 -p 32553 +short TXT "_acme-challenge.$route.$DOMAIN" 2>/dev/null)

    output="${result:+${result//$'\n'/, }}"
    output="${output:-null}"

    echo -n "Input: _acme-challenge.$route.$DOMAIN, Output: $output "

    if [[ -n "$result" && "$expected" == "true" ]]; then
        echo -e "[${GREEN}OK${NC}]"
    elif [[ -z "$result" && "$expected" == "false" ]]; then
        echo -e "[${GREEN}OK${NC}]"
    else
        echo -e "[${RED}ERROR${NC}]"
    fi
done <<<"$certs"
