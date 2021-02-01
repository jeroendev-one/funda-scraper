#!/bin/bash
#set -x

# Variables
PRICE="175000"
DATE='date +"%d-%m-%Y %H:%M"'

mv enschede.json.output enschede.json.orig
scrapy crawl funda -o enschede.json > /dev/null 2>&1

cat enschede.json | jq '.[] | select (.price <= "'$PRICE'" and .aangeboden == "Vandaag")' > enschede.json.output
#cat enschede.json | jq '.[] | select (.price <= "'$PRICE'")' > enschede.json.output
rm -f enschede.json

function notify 
{
        echo '
	<html>

	<head>
	    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css">
	</head>

	<body>
        <div class="card text-white bg-dark mb-3" style="width: 22rem;">
                <img class="card-img-top" src='$photo' width="286" height="180" alt="Card image cap">
                <div class="card-body">
                  <h5 class="card-title"> '$address' </h5>
                 
		   <ul class="list-group list-group-flush">
		    <li class="list-group-item">Vraagprijs: &euro; '$price'</li>
		    <li class="list-group-item">Wijk: '$neighbourhood'</li>
		    <li class="list-group-item">Aantal kamers: '$aantal_kamers'</li>
		    <li class="list-group-item">Energielabel: '$energy_label'</li>
		    <li class="list-group-item">Bouwjaar: '$year'</li>
		  </ul>
                  <div class="card-body bg-dark mb-3">
		    <a href="'$url'" class="btn btn-primary card-link">Bekijk advertentie</a>
		  </div>
		</div>
        </div>
	</body>

	</html>' | mutt -e "set content_type=text/html" "admin@jeroendev.one" -s "Nieuw huis op funda.nl"
}

DIFF=$(diff enschede.json.output enschede.json.orig)
if [ ! -z "$DIFF" ] || [ ! -z $(grep price enschede.json.output) ]; 
	then 
		IFS=$'\n'
		for x in $(cat enschede.json.output | jq '.address') ; do
			if [ -z $(grep $x log.txt) ]; then
			  eval $(cat enschede.json.output | jq -r 'select(.address == '$x') | to_entries | .[] | .key + "=\"" + .value + "\""')
			  notify && echo "$DATE : Mail send for $x" >> log.txt 
			fi
		done
fi
		
