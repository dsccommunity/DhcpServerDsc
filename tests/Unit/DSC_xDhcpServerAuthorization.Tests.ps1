$script:dscModuleName = 'DhcpServerDsc'
$script:dscResourceName = 'DSC_xDhcpServerAuthorization'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Import the stub functions.
    Import-Module -Name "$PSScriptRoot/Stubs/DhcpServer_2016_OSBuild_14393_2395.psm1" -Force -DisableNameChecking
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        # Test TargetResource parameters with Ensure = 'Present'.
        $testPresentParams = @{
            IsSingleInstance = 'Yes'
            Ensure           = 'Present'
            DnsName          = 'test1.contoso.com'
            IPAddress        = '192.168.1.1'
            Verbose          = $true
        }

        # Test TargetResource parameters with Ensure = 'Absent'.
        $testAbsentParams = @{
            IsSingleInstance = 'Yes'
            Ensure           = 'Absent'
            DnsName          = 'test1.contoso.com'
            IPAddress        = '192.168.1.1'
            Verbose          = $true
        }

        <#
            Authorized server list with test1.contoso.com authorized.
            This needs to be a PSCustomObject to work with ValueFromPipelineByPropertyName
            when calling cmdlet Remove-DhcpServerInDC.
        #>
        $fakeDhcpServersPresent = @(
            [PSCustomObject] @{
                IPAddress = '192.168.1.1'
                DnsName   = 'test1.contoso.com'
            },
            [PSCustomObject] @{
                IPAddress = '192.168.1.2'
                DnsName   = 'test2.contoso.com'
            },
            [PSCustomObject] @{
                IPAddress = '192.168.1.3'
                DnsName   = 'test3.contoso.com'
            }
        )

        # Authorized server list with test1.contoso.com not authorized
        $fakeDhcpServersAbsent = @(
            @{
                IPAddress = '192.168.1.2'
                DnsName   = 'test2.contoso.com'
            },
            @{
                IPAddress = '192.168.1.3'
                DnsName   = 'test3.contoso.com'
            }
        )

        # Authorized server list with mismatched DnsName, but matched IPAddress
        $fakeDhcpServersMismatchDnsName = @(
            @{
                IPAddress = '192.168.1.1'
                DnsName   = 'test11.contoso.com'
            },
            @{
                IPAddress = '192.168.1.2'
                DnsName   = 'test2.contoso.com'
            },
            @{
                IPAddress = '192.168.1.3'
                DnsName   = 'test3.contoso.com'
            }
        )

        # Authorized server list with mismatched IPAddress, but matched DnsName
        $fakeDhcpServersMismatchIPAddress = @(
            @{
                IPAddress = '192.168.1.11'
                DnsName   = 'test1.contoso.com'
            },
            @{
                IPAddress = '192.168.1.2'
                DnsName   = 'test2.contoso.com'
            },
            @{
                IPAddress = '192.168.1.3'
                DnsName   = 'test3.contoso.com'
            }
        )

        Describe 'DSC_xDhcpServerAuthorization\Get-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module
            }

            It 'Returns a [System.Collection.Hashtable] type' {
                Mock -CommandName Get-DhcpServerInDC -MockWith {
                    return $fakeDhcpServersPresent
                }

                $result = Get-TargetResource @testPresentParams

                $result -is [System.Collections.Hashtable] | Should -Be $true
            }

            It 'Returns Ensure is Present when DHCP server authorization exists' {
                Mock -CommandName Get-DhcpServerInDC -MockWith {
                    return $fakeDhcpServersPresent
                }

                $result = Get-TargetResource @testPresentParams

                $result.Ensure | Should -Be 'Present'
            }

            It 'Returns Ensure is Absent when DHCP server authorization does not exist' {
                Mock -CommandName Get-DhcpServerInDC

                $result = Get-TargetResource @testPresentParams

                $result.Ensure | Should -Be 'Absent'
            }

        }

        Describe 'DSC_xDhcpServerAuthorization\Test-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module
            }

            It 'Returns a [System.Boolean] type' {
                Mock Get-DhcpServerInDC -MockWith {
                    return $fakeDhcpServersPresent
                }

                $result = Test-TargetResource @testPresentParams

                $result -is [System.Boolean] | Should -Be $true
            }

            It 'Fails when DHCP Server authorization does not exist and Ensure is Present' {
                Mock -CommandName Get-DhcpServerInDC -MockWith {
                    return $fakeDhcpServersAbsent
                }

                Test-TargetResource @testPresentParams | Should -Be $false
            }

            It 'Fails when DHCP Server authorization does exist and Ensure is Absent' {
                Mock -CommandName Get-DhcpServerInDC -MockWith {
                    return $fakeDhcpServersPresent
                }

                Test-TargetResource @testAbsentParams | Should -Be $false
            }

            It 'Fails when DHCP Server authorization does exist, Ensure is Present but DnsName is wrong' {
                Mock -CommandName Get-DhcpServerInDC -MockWith {
                    return $fakeDhcpServersMismatchDnsName
                }

                Test-TargetResource @testPresentParams | Should -Be $false
            }

            It 'Fails when DHCP Server authorization does exist, Ensure is Present but IPAddress is wrong' {
                Mock -CommandName Get-DhcpServerInDC -MockWith {
                    return $fakeDhcpServersMismatchIPAddress
                }

                Test-TargetResource @testPresentParams | Should -Be $false
            }

            It 'Passes when DHCP Server authorization does exist and Ensure is Present' {
                Mock -CommandName Get-DhcpServerInDC -MockWith {
                    return $fakeDhcpServersPresent
                }

                $result = Test-TargetResource @testPresentParams

                $result -is [System.Boolean] | Should -Be $true
            }

            It 'Passes when DHCP Server authorization does not exist and Ensure is Absent' {
                Mock Get-DhcpServerInDC -MockWith {
                    return $fakeDhcpServersAbsent
                }

                $result = Test-TargetResource @testAbsentParams

                $result -is [System.Boolean] | Should -Be $true
            }
        }

        Describe 'DSC_xDhcpServerAuthorization\Set-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module
            }

            It 'Calls Add-DhcpServerInDc when Ensure is Present' {
                Mock -CommandName Add-DhcpServerInDC

                Set-TargetResource @testPresentParams

                Assert-MockCalled -CommandName Add-DhcpServerInDC -Exactly -Times 1 -Scope It
            }
            It 'Calls Remove-DhcpServerInDc when Ensure is Present' {
                Mock -CommandName Get-DhcpServerInDC -MockWith {
                    return $fakeDhcpServersPresent
                }

                Mock -CommandName Remove-DhcpServerInDC

                Set-TargetResource @testAbsentParams

                Assert-MockCalled -CommandName Remove-DhcpServerInDC -Exactly -Times 1 -Scope It
            }
        }

        Describe 'DSC_xDhcpServerAuthorization\Get-IPv4Address' {
            It 'Returns a IPv4 address' {
                $result = Get-IPv4Address -Verbose | Select-Object -First 1

                $result -match '\d+\.\d+\.\d+\.\d+' | Should -Be $true
            }
        }

        Describe 'DSC_xDhcpServerAuthorization\Get-Hostname' {
            It 'Returns at least the current NetBIOS name' {
                $hostname = [System.Net.Dns]::GetHostname()

                $result = Get-Hostname -Verbose

                $result -match $hostname | Should -Be $true
            }
        }
    } #end InModuleScope
}
finally
{
    Invoke-TestCleanup
}
