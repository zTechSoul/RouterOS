:global ListName;
:global Domains;
:global verbose;
:global Processing;

# Initialize the global lock if not set
:if ([:typeof $Processing] != "boolean") do={
    :set Processing false;
}

# Wait for the lock to be released
:if ($Processing) do={
    :error "Script is already running";
}

# Block other runs
:set Processing true;

:if ($verbose = true) do={ :log info ("Starting domain resolution for list: " . $ListName . ". Domains count: " . [:len $Domains]); }

# Prepare the data structures
:local typeA "A";
:local typeCName "CNAME";
:local domainsToProcess ($Domains); # Use a copy for processing
:local processedDnsValues [:toarray ""];
:local domainResolvedDnsAddresses [:toarray ""];

# Iterative processing loop instead of recursion
:while ([:len $domainsToProcess] > 0) do={
    :local currentDomain [:pick $domainsToProcess 0];
    :set domainsToProcess [:toarray [:pick $domainsToProcess 1 [:len $domainsToProcess]]];

    # Skip if already processed
    :if ([:len [:find $processedDnsValues $currentDomain]] = 0) do={
        # Add to processed list
        :set processedDnsValues ($processedDnsValues, $currentDomain);

        # Resolve the domain and process the records
        :if ($verbose = true) do={ :log info ("resolving " . $currentDomain); }

        :local resolveSuccess false;
        :onerror e {
            :resolve $currentDomain;
            :set resolveSuccess true;
        } do={
            :if ($verbose = true) do={ :log warning ("Failed to resolve domain: " . $currentDomain ); }
        }
        :if ($resolveSuccess = true) do={\
            :foreach dnsRecord in=[/ip dns cache all find where (name=$currentDomain)] do={
                :local recordType [/ip dns cache all get $dnsRecord type];
                :local recordData [/ip dns cache all get $dnsRecord data];

                :if ($recordType = $typeA) do={
                    :set domainResolvedDnsAddresses ($domainResolvedDnsAddresses, $recordData);
                }
                :if ($recordType = $typeCName) do={
                    :set domainsToProcess ($domainsToProcess, $recordData);
                }
            }
        }
    }
}

:if ($verbose = true) do={ :log info ("Removing outdated entries from address list: $ListName resolved IPs: " . [:len $domainResolvedDnsAddresses]); }

# From Address-List remove missing resolved IPs
:foreach addressListItem in=[/ip firewall address-list find list=$ListName] do={
    :local addressListItemAddress [/ip firewall address-list get $addressListItem address];
    :local found false;
    :foreach resolvedIp in=$domainResolvedDnsAddresses do={
        :if ($addressListItemAddress = $resolvedIp) do={
            :set found true;
        }
    }

    :if ($found = false) do={
        /ip firewall address-list remove $addressListItem;
    }
}

:if ($verbose = true) do={ :log info ("Adding new resolved IPs to address list: $ListName resolved IPs: " . [:len $domainResolvedDnsAddresses]); }

# Add new IPs to Address-List
:foreach resolvedIp in=$domainResolvedDnsAddresses do={
    :local found false;
    :foreach existingAddress in=[/ip firewall address-list find list=$ListName] do={
        :if ([/ip firewall address-list get $existingAddress address] = $resolvedIp) do={
            :set found true;
        }
    }

    :if ($found != true) do={
        /ip firewall address-list add list=$ListName address=$resolvedIp;
    }
}

# Release the lock
:set Processing false;
:if ($verbose = true) do={ :log info ("Script finished for list: $ListName"); }