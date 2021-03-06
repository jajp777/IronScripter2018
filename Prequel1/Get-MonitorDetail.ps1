function Get-MonitorDetail {
    [OutputType('MonitorDetail')]
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [System.Management.Automation.CredentialAttribute()]
        [pscredential]$Credential
    )

    begin {
        $PSDefaultParameterValues = @{
            'Get-CimInstance:Verbose' = $false
        }
    }

    process {
        foreach ($computer in $ComputerName) {
            Write-Verbose -Message "Querying computer [$computer]"

            try {
                # Support remote machines with optional credential
                $cimParams = @{}
                if ($computer -ne $env:COMPUTERNAME) {
                    $cimParams.ComputerName = $computer
                    if ($Credential) {
                        $cimParams.CimSession = New-CimSession -ComputerName $computer -Credential $Credential
                    }
                }

                # Get computer and monitor info
                $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem @cimParams -ErrorAction Stop
                $serialNumber = Get-CimInstance -ClassName Win32_Bios @cimParams | Select-Object -ExpandProperty SerialNumber
                $monitors = Get-CimInstance -ClassName wmiMonitorID -Namespace root\wmi @cimParams
                $monitors | ForEach-Object {
                    [PSCustomObject]@{
                        PSTypeName     = 'MonitorDetail'
                        ComputerName   = $computer
                        ComputerType   = $computerInfo.Model
                        ComputerSerial = $serialNumber
                        MonitorSerial  = [System.Text.Encoding]::Default.GetString($_.SerialNumberID)
                        MonitorType    = [System.Text.Encoding]::Default.GetString($_.UserFriendlyName)
                    }
                }
            } catch {
                Write-Error -Message "Unable to connect to [$computer]"
            } finally {
                if ($cimParams.CimSession) {
                    $cimParams.CimSession | Remove-CimSession
                }
            }
        }
    }
}
