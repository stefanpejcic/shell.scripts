#! /bin/bash
##############################################################################################################
# DESC: scan certs for issuer and EOL, write results to csv
###############################################################################################################
# Copyright (c) Chris Ruettimann <chris@bitbull.ch>

# This software is licensed to you under the GNU General Public License.
# There is NO WARRANTY for this software, express or
# implied, including the implied warranties of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
# along with this software; if not, see
# http://www.gnu.org/licenses/gpl.txt

# write results to
CSV=/tmp/cert_csv_report.csv

# ports to try
PORTS="443 50443 8443"

WAIT_SEC=2

IP_RANGES='
ogate.office.bitbull.ch
192.168.223.{40..254}
192.168.123.{1..254}
'


echo "IP,DNS,ISSUER,SUBJECT,START,EXPIRE,DAYS"
for range in $IP_RANGES
do 
   bash -c "echo $range" | tr ' ' '\n' | while read host
   do
      line=$(curl -kvv --max-time $WAIT_SEC https://$host 2>&1 | egrep 'issuer:|expire date:|start date:|subject:' | sed 's/.*: //' | tr -d ',' | tr '\n' ',')
      issuer=$(echo $line | cut -d, -f4 | tr -d ';')
      subject=$(echo $line | cut -d, -f1 | tr -d ';' | sed 's/.*CN=/CN=/')
      start=$(echo $line | cut -d, -f2)
      expire=$(echo $line | cut -d, -f3)
      end_date_seconds=`date '+%s' --date "$expire"`
      now_seconds=`date '+%s'`
      end_days=$(echo "($end_date_seconds-$now_seconds)/24/3600" | bc)
      echo $host | egrep -q '[a-zA-Z]'
      if [ $? -eq 0 ] ; then
         dns=$host
         ip=$(host $dns | sed 's/.* //' | grep '\.')
      else
        dns=$(host $host | sed 's/.* //' | grep '\.')
        ip=$host
      fi
      if [ "x$expire" != "x" ] ; then
         echo $ip,$dns,$issuer,$subject,$start,$expire,$end_days
      fi
   done

done 