<#
    .SYNOPSIS
        Unit test for Assert-ScopeParameter.
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
                & "$PSScriptRoot/../../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
