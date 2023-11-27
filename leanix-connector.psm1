class LeanIXConnector{
    hidden [string]$AccessToken
    hidden [string]$TokenType
    hidden [Datetime]$TokenCreated
    hidden [int]$ValidFor


    [SecureString]$ApiToken
    [string]$LeanIxInstance

    # Constructor
    LeanIXConnector([SecureString]$Token, [string]$Instance){
        $this.ApiToken = $Token
        $this.LeanIxInstance = $Instance
    }

    # Check if the token is expired
    hidden [bool]TokenExpired(){
        return $this.TokenCreated.AddSeconds($this.ValidFor) -lt [datetime]::Now
    }

    # call the login url and store the access token
    hidden [void]Login(){
        try{
            $tk = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.ApiToken))
            
            [string]$auth_url = "https://$($this.LeanIxInstance).leanix.net/services/mtm/v1/oauth2/token"
            [string]$auth = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("apitoken:$($tk)"))

            [Hashtable]$headers = @{
                "Authorization" = "Basic $auth"
            }

            [Hashtable]$data = @{
                "grant_type" = "client_credentials"
            }

            $this.TokenCreated = [datetime]::Now
            [PSCustomObject]$response = Invoke-RestMethod -Uri $auth_url -Method POST -Headers $headers -Body $data -ErrorAction Stop
            $this.AccessToken = $response.access_token
            $this.TokenType = $response.token_type
            $this.ValidFor = [int]$response.expires_in
        }
        catch{
            throw $_
        }
    }

    # query leanix graphql url
    hidden [PSCustomObject]MakeQuery([Hashtable]$query){
        try{
            if ($this.TokenExpired()){
                $this.Login()
            }

            [string]$jsonQuery = $query | ConvertTo-Json -ErrorAction Stop

            [Hashtable]$headers = @{
                "Authorization" = "$($this.TokenType) $($this.AccessToken)"
                "Content-Type" = "application/json"
            }

            [string]$request_url = "https://$($this.LeanIxInstance).leanix.net/services/pathfinder/v1/graphql"

            [PSCustomObject]$response = Invoke-RestMethod -Uri $request_url -Method Post -Headers $headers -Body $jsonQuery
            return $response
        }
        catch{
            throw $_
        }
    }
    
    # query factsheets
    hidden [PSCustomObject]_GetFactsheets([string]$queryfilter){
        try{
            [string]$graphqlQuery = "
            {
              allFactSheets$queryfilter {
                totalCount
                edges {
                  node {
                    id
                    displayName
                    fullName
                    __typename
        
        
                    ... on Application {
          
                      externalId {
                        externalId
                      }
                    }
                    ... on Project {
                      externalId {
                        externalId
                      }
                    }
                    ... on BaseFactSheet {          
                      description
                      subscriptions {
                        edges {
                          node {
                            user {
                              ... on User {
                                userName
                                email
                                displayName
                              }
                            }
                            roles{
                              name
                              comment
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }"


            [Hashtable]$query = @{
                query = $graphqlQuery
                }
            [PSCustomObject]$response = $this.MakeQuery($query)

            if ($response.errors){
                throw $response.errors
            }
            return $response.data.allFactSheets.edges.node | select id,
                        displayName,
                        fullname,
                        description,
                        @{n='type';e={$_.__typename}},
                        @{n='externalId';e={$_.externalId.externalId}},
                        @{n='owners';e={$_.subscriptions.edges.node | select @{n='Username';e={$_.user.username}},
                                                                                @{n='Mail';e={$_.user.email}},
                                                                                @{n='DisplayName';e={$_.user.displayname}},
                                                                                @{n='Role';e={$_.roles[0].name}}}}
        }
        catch{
            throw $_
        }
    }
    
    [PSCustomObject]GetFactsheets(){
        return $this._GetFactsheets('')
    }
    [PSCustomObject]GetFactsheets([Hashtable]$filter){
        $queryFilter = "(filter: {$($filter.Keys[0]): $($filter.Values[0])})"
        return $this._GetFactsheets($queryFilter)
    }
}
