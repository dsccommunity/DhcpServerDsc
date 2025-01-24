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
    $script:dscResourceName = 'DSC_DhcpServerBinding'

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


$interfaceAlias = 'Ethernet'
$ensure = 'Present'
$ipAddress = '10.0.0.1'

$testParamsPresent = @{
    InterfaceAlias = 'Ethernet'
    Ensure         = 'Present'
}

$testParamsAbsent = @{
    InterfaceAlias = 'Ethernet'
    Ensure         = 'Absent'
}

$badAliasParams = @{
    InterfaceAlias = 'fake'
    Ensure         = 'Present'
}

$setParamsAbsent = @{
    BindingState   = $false
    InterfaceAlias = 'Ethernet'
}

$bindingNotPreset = , @(
    [PSCustomObject] @{
        InterfaceAlias = 'Ethernet'
        IPAddress      = [IPAddress] '10.0.0.1'
        BindingState   = $false
    }
)

$bindingPresent = , @(
    [PSCustomObject] @{
        InterfaceAlias = 'Ethernet'
        IPAddress      = [IPAddress] '10.0.0.1'
        BindingState   = $true
    }
)

Describe 'DhcpServerBinding\Get-TargetResource' -Tag 'Get' {
    Context 'When the resource exists' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-DhcpServerv4Binding -MockWith {
                , @(
                    @{
                        InterfaceAlias = 'Ethernet'
                        IPAddress      = [IPAddress] '10.0.0.1'
                        BindingState   = $true
                    }
                )
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    InterfaceAlias = 'Ethernet'
                }

                $result = Get-TargetResource @testParams

                $result.InterfaceAlias | Should -Be $testParams.InterfaceAlias
                $result.Ensure | Should -Be 'Present'
            }

            Should -Invoke -CommandName Assert-Module -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DhcpServerv4Binding -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the resource does not exist' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-DhcpServerv4Binding -MockWith {
                , @(
                    @{
                        InterfaceAlias = 'Ethernet'
                        IPAddress      = [IPAddress] '10.0.0.1'
                        BindingState   = $false
                    }
                )
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    InterfaceAlias = 'Ethernet'
                }

                $result = Get-TargetResource @testParams

                $result.InterfaceAlias | Should -Be $testParams.InterfaceAlias
                $result.Ensure | Should -Be 'Absent'
            }

            Should -Invoke -CommandName Assert-Module -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DhcpServerv4Binding -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the InterfaceAlias is missing' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-DhcpServerv4Binding
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    InterfaceAlias = 'fake'
                }

                $errorRecord = Get-ObjectNotFoundRecord -Message (
                    $script:localizedData.InterfaceAliasIsMissing -f $testParams.InterfaceAlias, (Get-ComputerName)
                )


                { Get-TargetResource @testParams } | Should -Throw -ExpectedMessage $errorRecord
            }

            Should -Invoke -CommandName Assert-Module -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DhcpServerv4Binding -Exactly -Times 1 -Scope It
        }
    }
}


Describe 'DhcpServerBinding\Test-TargetResource' -Tag 'Test' {
    Context 'When the resource exists' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    InterfaceAlias = 'Ethernet'
                    Ensure         = 'Present'
                }
            }
        }

        Context 'When the resource should be Present' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        InterfaceAlias = 'Ethernet'
                        Ensure         = 'Present'
                    }

                    $result = Test-TargetResource @testParams

                    $result | Should -BeOfType [System.Boolean]
                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Assert-Module -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the resource should be Absent' {
            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        InterfaceAlias = 'Ethernet'
                        Ensure         = 'Absent'
                    }

                    $result = Test-TargetResource @testParams

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Assert-Module -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DhcpServerBinding\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Assert-Module
        Mock -CommandName Set-DhcpServerv4Binding -MockWith {
            return @{
                InterfaceAlias = 'Ethernet'
                IPAddress      = [IPAddress] '10.0.0.1'
                BindingState   = $false
            }
        }
    }

    It 'Should call expected mocks' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $testParams = @{
                InterfaceAlias = 'Ethernet'
                Ensure         = 'Present'
            }

            Set-TargetResource @testParams
        }

        Should -Invoke -CommandName Set-DhcpServerv4Binding -Exactly -Times 1 -Scope It
    }
}
