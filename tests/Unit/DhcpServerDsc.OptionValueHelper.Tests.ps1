<#
    .SYNOPSIS
        Unit test for DhcpServerDsc OptionValueHelper.
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
    $script:subModuleName = 'DhcpServerDsc.OptionValueHelper'

    $script:parentModule = Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -Force -ErrorAction 'Stop'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '.\Stubs\DhcpServer_2016_OSBuild_14393_2395.psm1')

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

    Remove-Module -Name 'DhcpServer_2016_OSBuild_14393_2395' -Force
}

Describe 'DhcpServerDsc.OptionValueHelper\Get-TargetResourceHelper' {
    BeforeDiscovery {
        $testCases = @(
            @{
                mockParameters = @{
                    ApplyTo       = 'Server'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    AddressFamily = 'IPv4'
                }

                mockResult     = @{
                    OptionId = 1
                }
            }
            @{
                mockParameters = @{
                    ApplyTo       = 'Scope'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    ScopeId       = '192.168.10.0'
                    AddressFamily = 'IPv4'
                }

                mockResult     = @{
                    OptionId = 1
                }
            }
            @{
                mockParameters = @{
                    ApplyTo       = 'Policy'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    ScopeId       = '192.168.10.0'
                    AddressFamily = 'IPv4'
                }

                mockResult     = @{
                    OptionId = 1
                }
            }
            @{
                mockParameters = @{
                    ApplyTo       = 'Policy'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    AddressFamily = 'IPv4'
                }

                mockResult     = @{
                    OptionId = 1
                }
            }
            @{
                mockParameters = @{
                    ApplyTo       = 'ReservedIP'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    ReservedIP    = '192.168.10.0'
                    AddressFamily = 'IPv4'
                }

                mockResult     = @{
                    OptionId = 1
                }
            }
        )
    }

    BeforeAll {
        Mock -CommandName Assert-Module
    }

    Context 'When the the DhcpOption Exists' {
        Context 'When ApplyTo is ''<mockParameters.ApplyTo>''' -ForEach $testCases {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith {
                    $mockResult
                }
            }

            It 'Should return the correct result' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResourceHelper @mockParameters

                    $result.Ensure | Should -Be 'Present'
                    $result.AddressFamily | Should -Be 'IPv4'
                }

                Should -Invoke -CommandName Get-DhcpServerv4OptionValue -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the the DhcpOption does not exist' {
        Context 'When ApplyTo is ''<mockParameters.ApplyTo>''' -ForEach $testCases {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4OptionValue
            }

            It 'Should return the correct result' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResourceHelper @mockParameters

                    $result.Ensure | Should -Be 'Absent'
                    $result.AddressFamily | Should -BeNullOrEmpty
                }

                Should -Invoke -CommandName Get-DhcpServerv4OptionValue -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DhcpServerDsc.OptionValueHelper\Test-TargetResourceHelper' {
    BeforeDiscovery {
        $testCases = @(
            @{
                mockParameters = @{
                    ApplyTo       = 'Server'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    AddressFamily = 'IPv4'
                    Value         = '10'
                }

                mockResult     = @{
                    Value = '10'
                }
            }
            @{
                mockParameters = @{
                    ApplyTo       = 'Scope'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    ScopeId       = '192.168.0.1'
                    AddressFamily = 'IPv4'
                    Value         = '10'
                }

                mockResult     = @{
                    Value = '10'
                }
            }
            @{
                mockParameters = @{
                    ApplyTo       = 'Policy'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    ScopeId       = '192.168.0.1'
                    AddressFamily = 'IPv4'
                    Value         = '10'
                }

                mockResult     = @{
                    Value = '10'
                }
            }
            @{
                mockParameters = @{
                    ApplyTo       = 'ReservedIP'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    ScopeId       = '192.168.0.1'
                    AddressFamily = 'IPv4'
                    Value         = '10'
                }

                mockResult     = @{
                    Value = '10'
                }
            }
        )
    }

    Context 'When the DhcpOption should exist and does for <mockParameters.ApplyTo>' -ForEach $testCases {
        BeforeAll {
            Mock -CommandName Get-TargetResourceHelper -ParameterFilter {
                $ApplyTo -eq $mockParameters.ApplyTo
            } -MockWith {
                $mockResult
            }
        }

        It 'Should return the correct result' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockResult.Ensure = 'Present'

                $result = Test-TargetResourceHelper @mockParameters

                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Get-TargetResourceHelper -ParameterFilter {
                $ApplyTo -eq $mockParameters.ApplyTo
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the DhcpOption should exist and does not for <mockParameters.ApplyTo>' -ForEach $testCases {
        BeforeAll {
            Mock -CommandName Get-TargetResourceHelper -ParameterFilter {
                $ApplyTo -eq $mockParameters.ApplyTo
            } -MockWith {
                @{
                    Ensure = 'Absent'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Test-TargetResourceHelper @mockParameters

                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Get-TargetResourceHelper -ParameterFilter {
                $ApplyTo -eq $mockParameters.ApplyTo
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the DhcpOption should not exist and does for <mockParameters.ApplyTo>' -ForEach $testCases {
        BeforeAll {
            Mock -CommandName Get-TargetResourceHelper -ParameterFilter {
                $ApplyTo -eq $mockParameters.ApplyTo
            } -MockWith {
                $mockResult
            }
        }

        It 'Should return the correct result' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters.Ensure = 'Absent'
                $mockResult.Ensure = 'Present'

                $result = Test-TargetResourceHelper @mockParameters

                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Get-TargetResourceHelper -ParameterFilter {
                $ApplyTo -eq $mockParameters.ApplyTo
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the DhcpOption should not exist and does for <mockParameters.ApplyTo>' -ForEach $testCases {
        BeforeAll {
            Mock -CommandName Get-TargetResourceHelper -ParameterFilter {
                $ApplyTo -eq $mockParameters.ApplyTo
            } -MockWith {
                @{
                    Ensure = 'Absent'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters.Ensure = 'Absent'

                $result = Test-TargetResourceHelper @mockParameters

                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Get-TargetResourceHelper -ParameterFilter {
                $ApplyTo -eq $mockParameters.ApplyTo
            } -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DhcpServerDsc.OptionValueHelper\Set-TargetResourceHelper' {
    BeforeDiscovery {
        $testCases = @(
            @{
                mockParameters = @{
                    ApplyTo       = 'Server'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    AddressFamily = 'IPv4'
                    Value         = '10'
                }

                mockResult     = @{
                    Value = '10'
                }
            }
            @{
                mockParameters = @{
                    ApplyTo       = 'Scope'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    ScopeId       = '192.168.0.1'
                    AddressFamily = 'IPv4'
                    Value         = '10'
                }

                mockResult     = @{
                    Value    = '10'
                    OptionId = 1
                }
            }
            @{
                mockParameters = @{
                    ApplyTo       = 'Policy'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    ScopeId       = '192.168.0.1'
                    AddressFamily = 'IPv4'
                    Value         = '10'
                }

                mockResult     = @{
                    Value = '10'
                }
            }
            @{
                mockParameters = @{
                    ApplyTo       = 'Policy'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    AddressFamily = 'IPv4'
                    Value         = '10'
                }

                mockResult     = @{
                    Value = '10'
                }
            }
            @{
                mockParameters = @{
                    ApplyTo       = 'ReservedIP'
                    OptionId      = 1
                    VendorClass   = ''
                    UserClass     = ''
                    ScopeId       = '192.168.0.1'
                    AddressFamily = 'IPv4'
                    Value         = '10'
                    ReservedIP    = '10.0.0.100'
                }

                mockResult     = @{}
            }
        )
    }

    Context 'When the DhcpOption should exist for <mockParameters.ApplyTo>' -ForEach $testCases {
        BeforeAll {
            Mock -CommandName Get-TargetResourceHelper -ParameterFilter {
                $ApplyTo -eq $mockParameters.ApplyTo
            } -MockWith {
                $mockResult
            }

            Mock -CommandName Set-DhcpServerv4OptionValue
        }

        It 'Should call the correct mocks' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockResult.Ensure = 'Present'

                $result = Set-TargetResourceHelper @mockParameters
            }

            Should -Invoke -CommandName Get-TargetResourceHelper -ParameterFilter {
                $ApplyTo -eq $mockParameters.ApplyTo
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Set-DhcpServerv4OptionValue -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the DhcpOption should not exist for <mockParameters.ApplyTo>' -ForEach $testCases {
        BeforeAll {
            Mock -CommandName Get-TargetResourceHelper -ParameterFilter {
                $ApplyTo -eq $mockParameters.ApplyTo
            } -MockWith {
                $mockResult
            }

            Mock -CommandName Remove-DhcpServerv4OptionValue
        }

        It 'Should return the correct result' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParameters.Ensure = 'Absent'
                $mockResult.Ensure = 'Present'

                $result = Set-TargetResourceHelper @mockParameters
            }

            Should -Invoke -CommandName Get-TargetResourceHelper -ParameterFilter {
                $ApplyTo -eq $mockParameters.ApplyTo
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Remove-DhcpServerv4OptionValue -Exactly -Times 1 -Scope It
        }
    }
}
