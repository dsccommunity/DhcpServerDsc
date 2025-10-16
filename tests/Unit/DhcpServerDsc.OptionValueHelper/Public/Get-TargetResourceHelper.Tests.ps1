<#
    .SYNOPSIS
        Unit test for Get-TargetResourceHelper.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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
    $script:subModuleName = 'DhcpServerDsc.OptionValueHelper'

    $script:parentModule = Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -Force -ErrorAction 'Stop'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Stubs\DhcpServer_2016_OSBuild_14393_2395.psm1') -DisableNameChecking

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
                testParams = @{
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
                testParams = @{
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
                testParams = @{
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
                testParams = @{
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
                testParams = @{
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

    Context 'When the DhcpOption Exists' {
        Context 'When ApplyTo is ''<testParams.ApplyTo>''' -ForEach $testCases {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith {
                    $mockResult
                }
            }

            It 'Should return the correct result' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResourceHelper @testParams

                    $result.Ensure | Should -Be 'Present'
                    $result.AddressFamily | Should -Be 'IPv4'
                }

                Should -Invoke -CommandName Get-DhcpServerv4OptionValue -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the DhcpOption does not exist' {
        Context 'When ApplyTo is ''<testParams.ApplyTo>''' -ForEach $testCases {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4OptionValue
            }

            It 'Should return the correct result' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResourceHelper @testParams

                    $result.Ensure | Should -Be 'Absent'
                    $result.AddressFamily | Should -BeNullOrEmpty
                }

                Should -Invoke -CommandName Get-DhcpServerv4OptionValue -Exactly -Times 1 -Scope It
            }
        }
    }
}
