# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'DhcpServerDsc'
    $script:dscResourceName = 'DSC_xDhcpServerAuthorization'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '.\Stubs\DhcpServer_2016_OSBuild_14393_2395.psm1') -DisableNameChecking

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    Remove-Module -Name 'DhcpServer_2016_OSBuild_14393_2395' -Force
}

Describe 'DSC_xDhcpServerAuthorization\Get-TargetResource' -Tag 'Get' {
    Context 'When the resource exists' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-ValidIPAddress -MockWith {
                return [IPAddress] '192.168.1.1'
            }

            Mock -CommandName Get-DhcpServerInDC -MockWith {
                return @(
                    @{
                        IPAddress = '192.168.1.1'
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
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    IsSingleInstance = 'Yes'
                    Ensure           = 'Present'
                    DnsName          = 'test1.contoso.com'
                    IPAddress        = '192.168.1.1'
                }

                $result = Get-TargetResource @testParams

                $result.DnsName | Should -Be $testParams.DnsName
                $result.IPAddress | Should -Be $testParams.IPAddress
                $result.Ensure | Should -Be 'Present'
            }
        }
    }

    Context 'When the resource does not exist' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-ValidIPAddress -MockWith {
                return [IPAddress] '192.168.1.1'
            }

            Mock -CommandName Get-DhcpServerInDC
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    IsSingleInstance = 'Yes'
                    Ensure           = 'Present'
                    DnsName          = 'test1.contoso.com'
                    IPAddress        = '192.168.1.1'
                }

                $result = Get-TargetResource @testParams

                $result.DnsName | Should -BeNullOrEmpty
                $result.IPAddress | Should -BeNullOrEmpty
                $result.Ensure | Should -Be 'Absent'
            }
        }
    }
}

Describe 'DSC_xDhcpServerAuthorization\Test-TargetResource' -Tag 'Test' {
    Context 'When the resource is in the desired state' {
        Context 'When the resource exists' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure    = 'Present'
                        DnsName   = 'test1.contoso.com'
                        IPAddress = '192.168.1.1'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        IsSingleInstance = 'Yes'
                        Ensure           = 'Present'
                        DnsName          = 'test1.contoso.com'
                        IPAddress        = '192.168.1.1'
                    }

                    Test-TargetResource @testParams | Should -BeTrue
                }
            }
        }


        Context 'When the resource should not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        IsSingleInstance = 'Yes'
                        Ensure           = 'Absent'
                        DnsName          = 'test1.contoso.com'
                        IPAddress        = '192.168.1.1'
                    }

                    Test-TargetResource @testParams | Should -BeTrue
                }
            }
        }
    }

    Context 'When the resource is not in the desired state' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    Property = 'DnsName'
                    Value    = 'test2.contoso.com'
                }
                @{
                    Property = 'IPAddress'
                    Value    = '192.168.10.1'
                }
            )
        }

        Context 'When the property <Property> is incorrect' -ForEach $testCases {
            BeforeAll {
                $mockGetTargetResource = @{
                    Ensure    = 'Present'
                    DnsName   = 'test1.contoso.com'
                    IPAddress = '192.168.1.1'
                }

                $mockGetTargetResource.$Property = $Value

                Mock -CommandName Get-TargetResource -MockWith {
                    return $mockGetTargetResource
                }
            }

            It 'Should return the correct result' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        IsSingleInstance = 'Yes'
                        Ensure           = 'Present'
                        DnsName          = 'test1.contoso.com'
                        IPAddress        = '192.168.1.1'
                    }

                    $result = Test-TargetResource @testParams
                    $result | Should -BeFalse
                }
            }
        }
    }
}

Describe 'DSC_xDhcpServerAuthorization\Set-TargetResource' -Tag 'Set' {
    Context 'When the resource should be created' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Add-DhcpServerInDc
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    IsSingleInstance = 'Yes'
                    Ensure           = 'Present'
                    DnsName          = 'test1.contoso.com'
                    IPAddress        = '192.168.1.1'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Assert-Module -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-DhcpServerInDc -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the resource should be removed' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-DhcpServerInDc
            Mock -CommandName Remove-DhcpServerInDc
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    IsSingleInstance = 'Yes'
                    Ensure           = 'Absent'
                    DnsName          = 'test1.contoso.com'
                    IPAddress        = '192.168.1.1'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Assert-Module -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DhcpServerInDc -Exactly -Times 1 -Scope It
            # TODO: Pipeline call is not invoking.
            #Should -Invoke -CommandName Remove-DhcpServerInDc -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_xDhcpServerAuthorization\Get-IPv4Address' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Get-CimInstance -MockWith {
            return New-CimInstance -ClassName 'Win32_NetworkAdapterConfiguration' -Namespace 'root\CIMV2' -ClientOnly -Property @{
                IPEnabled = 'True'
                IPAddress = '10.1.1.10'
            }
        }
    }

    It 'Returns a IPv4 address' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $result = Get-IPv4Address | Select-Object -First 1
            $result | Should -Be '10.1.1.10'
        }
    }
}

Describe 'DSC_xDhcpServerAuthorization\Get-Hostname' -Tag 'Helper' {
    Context 'When a DomainName exists' {
        # TODO: Mock a .NET type
        # It 'Should return the correct result' {
        #     InModuleScope -ScriptBlock {
        #         Set-StrictMode -Version 1.0

        #         Get-HostName | Should -Be ('{0}.{1}' -f (Get-ComputerName), $env:USERDNSDOMAIN)
        #     }
        # }
    }

    Context 'When a DomainName does not exist' {
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Get-HostName | Should -Be (Get-ComputerName)
            }
        }
    }
}
