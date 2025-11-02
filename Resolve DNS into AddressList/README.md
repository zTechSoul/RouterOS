### What this script does

It takes array of domain names  
Prepares an array of Addresses from resolved domains A records  
It supports CNAME records

Checks target Address-List and:  
- Removes all Firewall Address-List addresses which are not in the Prepared Addresses array
- Adds all addresses which are not yet in the Firewall Address-List

## How to use:

### Step 1

Create new script in `/system/script`:

\# Name must match the value used in the scheduler script  
Name: `dnsToAddressList`  
Plicy: `read`, `write`, `test`, `sniff`  
Source: __Insert content of the file:__ `dnsToAddressList.rsc`

### Step 2

Create new scheduler in `/system/scheduler`:

Name: `check youtube` or another value  
Start Time: `startup`  
\# use the value which makes sense in your case  
Interval: `00:05:00`  
\# Policy must be same or more allowing that required by the script in `Step 1`  
Plicy: `read`, `write`, `test`, `sniff`  
OnEvent: __Insert content of the file:__ `SchedulerOnEvent.rsc`  
