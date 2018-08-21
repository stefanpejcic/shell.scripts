#!/bin/bash -e
#########################################################################################
# DESC: update luadns A record with wanip
#########################################################################################
# Copyright (c) Chris Ruettimann <chris@bitbull.ch>

# This software is licensed to you under the GNU General Public License.
# There is NO WARRANTY for this software, express or
# implied, including the implied warranties of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
# along with this software; if not, see
# http://www.gnu.org/licenses/gpl.txt

#--------------------------------------------------------
logit(){
   logger -t $(basename $0) "$*"
   echo "DEBUG LOG: $*"
}
#--------------------------------------------------------

LuaKey="4ceb50f2atghdsfvsdfhgdghy3456720"
LuaEmail="lua@bitbull.ch"
LuaApi="https://api.luadns.com/v1"
DynDnsARecord="office.bitbull.ch"
DynDnsTtl=300
DynDnsDomain=`echo $DynDnsARecord | cut -d. -f2-`
LuaNs=`host -t NS $DynDnsDomain | grep 'name server' | head -1 | sed 's/.* name server //'`
WanIp=`wget -q -O - ip.changeip.com | grep ^[0-9]`
DnsRecIp=`host -t A $DynDnsARecord $LuaNs | grep 'has address' | head -1 | sed 's/.* has address //'`
logit LuaNs=$LuaNs
logit DynDnsARecord=$DynDnsARecord
logit WanIp=$WanIp
logit DnsRecIp=$DnsRecIp

LuaDomainId=$(curl --silent -u $LuaEmail:$LuaKey -H 'Accept: application/json' \
        https://api.luadns.com/v1/zones |\
        sed 's/,/\n/g' | grep -A7 -B1 \"name\":\"$DynDnsDomain\" | grep '"id":' | cut -d: -f2)
logit LuaDomainId=$LuaDomainId

LuaARecordId=$(curl --silent -u $LuaEmail:$LuaKey -H 'Accept: application/json' \
        https://api.luadns.com/v1/zones/$LuaDomainId |\
        sed 's/,/\n/g' | grep -A7 -B1 \"name\":\"$DynDnsARecord | grep '"id":' | cut -d: -f2)
logit LuaARecordId=$LuaARecordId


if [ $WanIp != $DnsRecIp ]
then
logit updating $DynDnsARecord with IP $WanIp
   MSG=$(curl --silent -u $LuaEmail:$LuaKey \
        -X PUT \
        -d "{\"name\":\"$DynDnsARecord.\",\"type\":\"A\",\"content\":\"$WanIp\",\"ttl\":$DynDnsTtl}" \
        -H 'Accept: application/json' \
        https://api.luadns.com/v1/zones/$LuaDomainId/records/$LuaARecordId 2>&1)
   logit http reply: $MSG
else
   logit NO update needed
fi

logit $(basename $0) finished

