#!/usr/bin/env bash

DOMAIN="foo.org"

# Define the routes/should work
read -r -d '' routes <<'EOF'
good.ok true
target.ok true
abcd0123456789012345678901234567890123456789012345678901234567890 false
foo_bar false

myservicea true
myserviceb true
*.myservice true
asdf.myservice true
wasd.myservice true
ingress.target true

virtualservera true

myservicea.gw true
myserviceb.gw true
myservicec.gw-wrong false
myserviced.gw true
myservicetls.gw true
myservicegrpc.gw true

EOF

# ANSI color codes for output
GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m' # No Color

# Process each route from the list
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
