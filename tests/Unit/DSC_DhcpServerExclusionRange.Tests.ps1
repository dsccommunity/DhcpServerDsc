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
    $script:dscResourceName = 'DSC_DhcpServerExclusionRange'

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

Describe 'DhcpServerExclusionRange\Get-TargetResource' -Tag 'Get' {
    Context 'When the exclusion range exists' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                $ParameterName -eq 'ScopeId'
            } -MockWith {
                return [IPAddress] '10.1.1.0'
            }

            Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                $ParameterName -eq 'StartRange'
            } -MockWith {
                return [IPAddress] '10.1.1.10'
            }

            Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                $ParameterName -eq 'EndRange'
            } -MockWith {
                return [IPAddress] '10.1.1.20'
            }

            Mock -CommandName Get-DhcpServerv4ExclusionRange -MockWith {
                return @(
                    @{
                        ScopeId    = '10.1.1.0'
                        StartRange = [IPAddress] '10.1.1.10'
                        EndRange   = [IPAddress] '10.1.1.20'
                    }
                )
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeId       = '10.1.1.0'
                    IPStartRange  = '10.1.1.10'
                    IPEndRange    = '10.1.1.20'
                    AddressFamily = 'IPv4'
                }

                $result = Get-TargetResource @testParams

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.ScopeId | Should -Be $testParams.ScopeId
                $result.IPStartRange | Should -Be $testParams.IPStartRange
                $result.IPEndRange | Should -Be $testParams.IPEndRange
                $result.AddressFamily | Should -Be $testParams.AddressFamily
                $result.Ensure | Should -Be 'Present'
            }
        }
    }

    Context 'When the exclusion range does not exist' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                $ParameterName -eq 'ScopeId'
            } -MockWith {
                return [IPAddress] '10.1.1.0'
            }

            Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                $ParameterName -eq 'StartRange'
            } -MockWith {
                return [IPAddress] '10.1.1.10'
            }

            Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                $ParameterName -eq 'EndRange'
            } -MockWith {
                return [IPAddress] '10.1.1.20'
            }

            Mock -CommandName Get-DhcpServerv4ExclusionRange
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeId       = '10.1.1.0'
                    IPStartRange  = '10.1.1.10'
                    IPEndRange    = '10.1.1.20'
                    AddressFamily = 'IPv4'
                }

                $result = Get-TargetResource @testParams

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.ScopeId | Should -Be $testParams.ScopeId
                # Key properties should be returned??
                #$result.IPStartRange | Should -Be $testParams.IPStartRange
                #$result.IPEndRange | Should -Be $testParams.IPEndRange

                $result.IPStartRange | Should -BeNullOrEmpty
                $result.IPEndRange | Should -BeNullOrEmpty
                $result.AddressFamily | Should -Be $testParams.AddressFamily
                $result.Ensure | Should -Be 'Absent'
            }
        }
    }

    Context 'When the exclusion range is invalid' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                $ParameterName -eq 'ScopeId'
            } -MockWith {
                return [IPAddress] '10.1.1.0'
            }

            Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                $ParameterName -eq 'StartRange'
            } -MockWith {
                return [IPAddress] '10.1.1.20'
            }

            Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                $ParameterName -eq 'EndRange'
            } -MockWith {
                return [IPAddress] '10.1.1.10'
            }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeId       = '10.1.1.0'
                    IPStartRange  = '10.1.1.20'
                    IPEndRange    = '10.1.1.10'
                    AddressFamily = 'IPv4'
                }

                $errorMessageParams = @{
                    ArgumentName = 'StartRange'
                    Message      = $script:localizedData.InvalidStartAndEndRange
                }

                $errorMessage = Get-InvalidArgumentRecord @errorMessageParams

                { Get-TargetResource @testParams } | Should -Throw -ExpectedMessage $errorMessage
            }
        }
    }
}


Describe 'DhcpServerExclusionRange\Test-TargetResource' -Tag 'Test' {
    Context 'When the resource exists' {
        Context 'When the resource should exist' {
            BeforeAll {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                    $ParameterName -eq 'StartRange'
                } -MockWith {
                    return [IPAddress] '10.1.1.10'
                }

                Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                    $ParameterName -eq 'EndRange'
                } -MockWith {
                    return [IPAddress] '10.1.1.20'
                }

                Mock -CommandName Get-DhcpServerv4ExclusionRange -MockWith {
                    return @(
                        @{
                            ScopeId    = '10.1.1.0'
                            StartRange = [IPAddress] '10.1.1.10'
                            EndRange   = [IPAddress] '10.1.1.20'
                        }
                    )
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId       = '10.1.1.0'
                        IPStartRange  = '10.1.1.10'
                        IPEndRange    = '10.1.1.20'
                        AddressFamily = 'IPv4'
                        Ensure        = 'Present'
                    }

                    Test-TargetResource @testParams | Should -BeTrue
                }
            }
        }

        Context 'When the resource should not exist' {
            BeforeAll {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                    $ParameterName -eq 'StartRange'
                } -MockWith {
                    return [IPAddress] '10.1.1.10'
                }

                Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                    $ParameterName -eq 'EndRange'
                } -MockWith {
                    return [IPAddress] '10.1.1.20'
                }

                Mock -CommandName Get-DhcpServerv4ExclusionRange -MockWith {
                    return @(
                        @{
                            ScopeId    = '10.1.1.0'
                            StartRange = [IPAddress] '10.1.1.10'
                            EndRange   = [IPAddress] '10.1.1.20'
                        }
                    )
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId       = '10.1.1.0'
                        IPStartRange  = '10.1.1.10'
                        IPEndRange    = '10.1.1.20'
                        AddressFamily = 'IPv4'
                        Ensure        = 'Absent'
                    }

                    Test-TargetResource @testParams | Should -BeFalse
                }
            }
        }
    }

    Context 'When the resource does not exist' {
        Context 'When the resource should exist' {
            BeforeAll {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                    $ParameterName -eq 'StartRange'
                } -MockWith {
                    return [IPAddress] '10.1.1.10'
                }

                Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                    $ParameterName -eq 'EndRange'
                } -MockWith {
                    return [IPAddress] '10.1.1.20'
                }

                Mock -CommandName Get-DhcpServerv4ExclusionRange
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId       = '10.1.1.0'
                        IPStartRange  = '10.1.1.10'
                        IPEndRange    = '10.1.1.20'
                        AddressFamily = 'IPv4'
                        Ensure        = 'Present'
                    }

                    Test-TargetResource @testParams | Should -BeFalse
                }
            }
        }

        Context 'When the resource should not exist' {
            BeforeAll {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                    $ParameterName -eq 'StartRange'
                } -MockWith {
                    return [IPAddress] '10.1.1.10'
                }

                Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                    $ParameterName -eq 'EndRange'
                } -MockWith {
                    return [IPAddress] '10.1.1.20'
                }

                Mock -CommandName Get-DhcpServerv4ExclusionRange
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId       = '10.1.1.0'
                        IPStartRange  = '10.1.1.10'
                        IPEndRange    = '10.1.1.20'
                        AddressFamily = 'IPv4'
                        Ensure        = 'Absent'
                    }

                    Test-TargetResource @testParams | Should -BeTrue
                }
            }
        }
    }

    Context 'When the exclusion range is invalid' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                $ParameterName -eq 'StartRange'
            } -MockWith {
                return [IPAddress] '10.1.1.20'
            }

            Mock -CommandName Get-ValidIpAddress -ParameterFilter {
                $ParameterName -eq 'EndRange'
            } -MockWith {
                return [IPAddress] '10.1.1.10'
            }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeId       = '10.1.1.0'
                    IPStartRange  = '10.1.1.20'
                    IPEndRange    = '10.1.1.10'
                    AddressFamily = 'IPv4'
                    Ensure        = 'Present'
                }

                $errorMessageParams = @{
                    ArgumentName = 'StartRange'
                    Message      = $script:localizedData.InvalidStartAndEndRange
                }

                $errorMessage = Get-InvalidArgumentRecord @errorMessageParams

                { Test-TargetResource @testParams } | Should -Throw -ExpectedMessage $errorMessage
            }
        }
    }
}

Describe 'DhcpServerExclusionRange\Set-TargetResource' -Tag 'Set' {
    Context 'When the exclusion range should be created' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Add-DhcpServerv4ExclusionRange
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeId       = '10.1.1.0'
                    IPStartRange  = '10.1.1.10'
                    IPEndRange    = '10.1.1.20'
                    AddressFamily = 'IPv4'
                    Ensure        = 'Present'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Assert-Module -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-DhcpServerv4ExclusionRange -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the exclusion range should be created' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Remove-DhcpServerv4ExclusionRange
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeId       = '10.1.1.0'
                    IPStartRange  = '10.1.1.10'
                    IPEndRange    = '10.1.1.20'
                    AddressFamily = 'IPv4'
                    Ensure        = 'Absent'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Assert-Module -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-DhcpServerv4ExclusionRange -Exactly -Times 1 -Scope It
        }
    }
}
