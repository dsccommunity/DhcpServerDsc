<#
    .SYNOPSIS
        Unit test for DhcpServerDsc Common.
#>

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
    $script:subModuleName = 'DhcpServerDsc.Common'

    $script:parentModule = Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force
}

Describe 'DhcpServerDsc.Common\New-TerminatingError' {
    It 'Should throw a terminating error with the specified message' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $testParameters = @{
                ErrorId       = 'TestErrorId'
                ErrorMessage  = 'Test message'
                ErrorCategory = 'InvalidType'
            }

            { New-TerminatingError @testParameters } | Should -Throw -ExpectedMessage $testParameters.ErrorMessage
        }
    }
}

Describe 'DhcpServerDsc.Common\Get-ValidIPAddress' {
    Context 'When getting a valid IPv4 Address' {
        Context 'When the ''AddressFamily'' matches' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        IpString      = '255.255.255.0'
                        AddressFamily = 'IPv4'
                        ParameterName = 'SubnetMask'
                    }

                    $result = Get-ValidIPAddress @testParameters

                    $result | Should -BeOfType [System.Net.IPAddress]
                    $result | Should -Be $testParameters.IpString
                    $result.AddressFamily | Should -Be 'InterNetwork'
                }
            }
        }

        Context 'When the ''AddressFamily'' does not match' {
            BeforeAll {
                Mock -CommandName New-TerminatingError -ParameterFilter {
                    $ErrorId -eq 'NotValidIPAddress'
                } -MockWith { throw }

                Mock -CommandName New-TerminatingError -ParameterFilter {
                    $ErrorId -eq 'InvalidIPAddressFamily'
                } -MockWith { throw }
            }

            It 'Should return the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        IpString      = '255.255.255.0'
                        AddressFamily = 'IPv6'
                        ParameterName = 'SubnetMask'
                    }

                    { Get-ValidIPAddress @testParameters } | Should -Throw
                }

                Should -Invoke -CommandName New-TerminatingError -ParameterFilter {
                    $ErrorId -eq 'NotValidIPAddress'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName New-TerminatingError -ParameterFilter {
                    $ErrorId -eq 'InvalidIPAddressFamily'
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When getting an invalid IPv4 Address' {
        BeforeAll {
            Mock -CommandName New-TerminatingError -ParameterFilter {
                $ErrorId -eq 'NotValidIPAddress'
            } -MockWith { throw }

            Mock -CommandName New-TerminatingError -ParameterFilter {
                $ErrorId -eq 'InvalidIPAddressFamily'
            } -MockWith { throw }
        }

        It 'Should return the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters = @{
                    IpString      = '255.255.255.x'
                    AddressFamily = 'IPv4'
                    ParameterName = 'SubnetMask'
                }

                { Get-ValidIPAddress @testParameters } | Should -Throw
            }

            Should -Invoke -CommandName New-TerminatingError -ParameterFilter {
                $ErrorId -eq 'NotValidIPAddress'
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName New-TerminatingError -ParameterFilter {
                $ErrorId -eq 'InvalidIPAddressFamily'
            } -Exactly -Times 0 -Scope It
        }
    }

    Context 'When getting a valid IPv6 Address' {
        Context 'When the ''AddressFamily'' matches' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        IpString      = '2001:0db8:85a3:1234:1234:8a2e:0370:7334'
                        AddressFamily = 'IPv6'
                        ParameterName = 'SubnetMask'
                    }

                    $result = Get-ValidIPAddress @testParameters

                    $result | Should -BeOfType [System.Net.IPAddress]
                    $result | Should -Be '2001:db8:85a3:1234:1234:8a2e:370:7334'
                    $result.AddressFamily | Should -Be 'InterNetworkV6'
                }
            }
        }

        Context 'When the ''AddressFamily'' does not match' {
            BeforeAll {
                Mock -CommandName New-TerminatingError -ParameterFilter {
                    $ErrorId -eq 'NotValidIPAddress'
                } -MockWith { throw }

                Mock -CommandName New-TerminatingError -ParameterFilter {
                    $ErrorId -eq 'InvalidIPAddressFamily'
                } -MockWith { throw }
            }

            It 'Should return the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        IpString      = '2001:0db8:85a3:1234:1234:8a2e:0370:7334'
                        AddressFamily = 'IPv4'
                        ParameterName = 'SubnetMask'
                    }

                    { Get-ValidIPAddress @testParameters } | Should -Throw
                }

                Should -Invoke -CommandName New-TerminatingError -ParameterFilter {
                    $ErrorId -eq 'NotValidIPAddress'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName New-TerminatingError -ParameterFilter {
                    $ErrorId -eq 'InvalidIPAddressFamily'
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When getting an invalid IPv6 Address' {
        BeforeAll {
            Mock -CommandName New-TerminatingError -ParameterFilter {
                $ErrorId -eq 'NotValidIPAddress'
            } -MockWith { throw }

            Mock -CommandName New-TerminatingError -ParameterFilter {
                $ErrorId -eq 'InvalidIPAddressFamily'
            } -MockWith { throw }
        }

        It 'Should return the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters = @{
                    IpString      = '255.255.255.x'
                    AddressFamily = 'IPv6'
                    ParameterName = 'SubnetMask'
                }

                { Get-ValidIPAddress @testParameters } | Should -Throw
            }

            Should -Invoke -CommandName New-TerminatingError -ParameterFilter {
                $ErrorId -eq 'NotValidIPAddress'
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName New-TerminatingError -ParameterFilter {
                $ErrorId -eq 'InvalidIPAddressFamily'
            } -Exactly -Times 0 -Scope It
        }
    }
}

Describe 'DhcpServerDsc.Common\Assert-ScopeParameter' {
    Context 'When parameters are correct' {
        BeforeAll {
            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'SubnetMask'
            } -MockWith {
                return [System.Net.IPAddress] '255.255.255.0'
            }

            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'ScopeId'
            } -MockWith {
                return [System.Net.IPAddress] '192.168.1.0'
            }

            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'IPStartRange'
            } -MockWith {
                return [System.Net.IPAddress] '192.168.1.10'
            }

            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'IPEndRange'
            } -MockWith {
                return [System.Net.IPAddress] '192.168.1.99'
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeId       = '192.168.1.0'
                    IPStartRange  = '192.168.1.10'
                    IPEndRange    = '192.168.1.99'
                    SubnetMask    = '255.255.255.0'
                    AddressFamily = 'IPv4'
                }

                $result = Assert-ScopeParameter @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-ValidIPAddress -Exactly -Times 4 -Scope It
        }
    }

    Context 'When start or end range is not correct' {
        BeforeAll {
            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'SubnetMask'
            } -MockWith {
                return [System.Net.IPAddress] '255.255.255.0'
            }

            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'ScopeId'
            } -MockWith {
                return [System.Net.IPAddress] '192.168.1.0'
            }

            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'IPStartRange'
            } -MockWith {
                return [System.Net.IPAddress] '192.168.1.100'
            }

            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'IPEndRange'
            } -MockWith {
                return [System.Net.IPAddress] '192.168.1.99'
            }

            Mock -CommandName New-TerminatingError -ParameterFilter {
                $ErrorId -eq 'RangeNotCorrect'
            } -MockWith { throw }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeId       = '192.168.1.0'
                    IPStartRange  = '192.168.1.100'
                    IPEndRange    = '192.168.1.99'
                    SubnetMask    = '255.255.255.0'
                    AddressFamily = 'IPv4'
                }

                { Assert-ScopeParameter @testParams } | Should -Throw
            }

            Should -Invoke -CommandName Get-ValidIPAddress -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName New-TerminatingError -ParameterFilter {
                $ErrorId -eq 'RangeNotCorrect'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When Parameters parameter are incorrect' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    Parameter = 'ScopeId'
                    Value     = '192.168.1.42'
                    ErrorId   = 'ScopeIdOrMaskIncorrect'
                }
                @{
                    Parameter = 'IPStartRange'
                    Value     = '192.168.0.1'
                    ErrorId   = 'ScopeIdOrMaskIncorrect'
                }
                @{
                    Parameter = 'IPEndRange'
                    Value     = '192.167.1.100'
                    ErrorId   = 'ScopeIdOrMaskIncorrect'
                }
            )
        }

        Context 'When ''<Parameter>'' is incorrect' -ForEach $testCases {
            BeforeAll {
                Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                    $ParameterName -eq 'SubnetMask'
                } -MockWith {
                    return [System.Net.IPAddress] '255.255.255.0'
                }

                Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                    $ParameterName -eq 'ScopeId'
                } -MockWith {
                    return [System.Net.IPAddress] '192.168.1.0'
                }

                Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                    $ParameterName -eq 'IPStartRange'
                } -MockWith {
                    return [System.Net.IPAddress] '192.168.1.10'
                }

                Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                    $ParameterName -eq 'IPEndRange'
                } -MockWith {
                    return [System.Net.IPAddress] '192.168.1.99'
                }

                # Override the correct mock
                Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                    $ParameterName -eq $Parameter
                } -MockWith {
                    return [System.Net.IPAddress] $Value
                }

                Mock -CommandName New-TerminatingError -ParameterFilter {
                    $ErrorId -eq $ErrorId
                } -MockWith { throw }
            }

            It 'Should throw an exception with ErrorId <ErrorId> and information about incorrect <Parameter> (<Value>)' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId       = '192.168.1.0'
                        IPStartRange  = '192.168.1.10'
                        IPEndRange    = '192.168.1.99'
                        SubnetMask    = '255.255.255.0'
                        AddressFamily = 'IPv4'
                        Verbose       = $true
                    }

                    $testParams.$Parameter = $Value

                    { Assert-ScopeParameter @testParams } | Should -Throw
                }

                Should -Invoke -CommandName Get-ValidIPAddress -Exactly -Times 4 -Scope It
                Should -Invoke -CommandName New-TerminatingError -ParameterFilter {
                    $ErrorId -eq $ErrorId
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DhcpServerDsc.Common\Write-PropertyMessage' {
    Context 'When no keys need to be skipped' {
        BeforeAll {
            Mock -CommandName Write-Verbose
        }

        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Parameters      = @{
                        PropertyName  = 'TestProperty'
                        PropertyValue = 'TestValue'
                    }
                    KeysToSkip      = @('Somekey')
                    MessageTemplate = 'Mock message template {0}'
                }

                Write-PropertyMessage @testParams
            }

            Should -Invoke -CommandName Write-Verbose -Exactly -Times 2 -Scope It
        }
    }
}

Describe 'DhcpServerDsc.Common\Get-ValidTimeSpan' {
    Context 'When the TimeSpan string is valid' {
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters = @{
                    TsString      = '00:00:00'
                    ParameterName = 'LeaseDuration'
                }

                $result = Get-ValidTimeSpan @testParameters

                $result | Should -BeOfType [System.TimeSpan]
                $result | Should -Be '00:00:00'
            }
        }
    }

    Context 'When the TimeSpan string is not valid' {
        BeforeAll {
            Mock -CommandName New-TerminatingError -ParameterFilter {
                $ErrorId -eq 'NotValidTimeSpan'
            } -MockWith { throw }
        }
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters = @{
                    TsString      = '00:00:00?'
                    ParameterName = 'LeaseDuration'
                }

                { Get-ValidTimeSpan @testParameters } | Should -Throw
            }

            Should -Invoke -CommandName New-TerminatingError -ParameterFilter {
                $ErrorId -eq 'NotValidTimeSpan'
            } -Exactly -Times 1 -Scope It
        }
    }
}
