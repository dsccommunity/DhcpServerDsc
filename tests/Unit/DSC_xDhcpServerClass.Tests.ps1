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
    $script:dscResourceName = 'DSC_xDhcpServerClass'

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

Describe 'DSC_xDhcpServerClass\Get-TargetResource' -Tag 'Get' {
    Context 'When the resource exists' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-DhcpServerv4Class -MockWith {
                return @{
                    Name          = 'Test Class'
                    Type          = 'Vendor'
                    AsciiData     = 'test data'
                    Description   = 'test class description'
                    AddressFamily = 'IPv4'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name          = 'Test Class'
                    Type          = 'Vendor'
                    AsciiData     = 'test data'
                    AddressFamily = 'IPv4'
                    Description   = 'test class description'
                    Ensure        = 'Present'

                }

                $result = Get-TargetResource @testParams

                $result.Name | Should -Be $testParams.Name
                $result.Type | Should -Be $testParams.Type
                $result.AsciiData | Should -Be $testParams.AsciiData
                $result.Description | Should -Be $testParams.Description
                $result.AddressFamily | Should -Be $testParams.AddressFamily
            }
        }
    }

    Context 'When the resource does not exist' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-DhcpServerv4Class
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name          = 'Test Class'
                    Type          = 'Vendor'
                    AsciiData     = 'test data'
                    AddressFamily = 'IPv4'
                    Description   = 'test class description'
                    Ensure        = 'Present'
                }

                $result = Get-TargetResource @testParams

                $result.Name | Should -BeNullOrEmpty
                $result.Type | Should -BeNullOrEmpty
                $result.AsciiData | Should -BeNullOrEmpty
                $result.Description | Should -BeNullOrEmpty
                $result.AddressFamily | Should -BeNullOrEmpty
            }
        }
    }
}

Describe 'DSC_xDhcpServerClass\Test-TargetResource' -Tag 'Test' {
    Context 'When the resource is in the desired state' {
        Context 'When the resource should be present' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Class -MockWith {
                    return @{
                        Name          = 'Test Class'
                        Type          = 'Vendor'
                        AsciiData     = 'test data'
                        Description   = 'test class description'
                        AddressFamily = 'IPv4'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Name          = 'Test Class'
                        Type          = 'Vendor'
                        AsciiData     = 'test data'
                        AddressFamily = 'IPv4'
                        Description   = 'test class description'
                        Ensure        = 'Present'
                    }

                    Test-TargetResource @testParams | Should -BeTrue
                }
            }
        }

        Context 'When the resource should be absent' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Class
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Name          = 'Test Class'
                        Type          = 'Vendor'
                        AsciiData     = 'test data'
                        AddressFamily = 'IPv4'
                        Description   = 'test class description'
                        Ensure        = 'Absent'
                    }

                    Test-TargetResource @testParams | Should -BeTrue
                }
            }
        }
    }

    Context 'When the resource is not in the desired state' {
        Context 'When one property is incorrect' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Class -MockWith {
                    return @{
                        Name          = 'Test Class'
                        Type          = 'Vendor'
                        AsciiData     = 'test data'
                        Description   = 'test class description'
                        AddressFamily = 'IPv4'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Name          = 'Test Class'
                        Type          = 'Vendor'
                        AsciiData     = 'test data'
                        AddressFamily = 'IPv4'
                        Description   = 'test class description error'
                        Ensure        = 'Present'
                    }

                    Test-TargetResource @testParams | Should -BeFalse
                }
            }
        }

        Context 'When the resource should exist but does not' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Class
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Name          = 'Test Class'
                        Type          = 'Vendor'
                        AsciiData     = 'test data'
                        AddressFamily = 'IPv4'
                        Description   = 'test class description'
                        Ensure        = 'Present'
                    }

                    Test-TargetResource @testParams | Should -BeFalse
                }
            }
        }

        Context 'When the resource should not exist but does' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Class -MockWith {
                    return @{
                        Name          = 'Test Class'
                        Type          = 'Vendor'
                        AsciiData     = 'test data'
                        Description   = 'test class description'
                        AddressFamily = 'IPv4'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Name          = 'Test Class'
                        Type          = 'Vendor'
                        AsciiData     = 'test data'
                        AddressFamily = 'IPv4'
                        Description   = 'test class description'
                        Ensure        = 'Absent'
                    }

                    Test-TargetResource @testParams | Should -BeFalse
                }
            }
        }
    }
}

Describe 'DSC_xDhcpServerClass\Set-TargetResource' {
    Context 'When a resource needs creating' {
        BeforeAll {
            Mock -CommandName Get-DhcpServerv4Class
            Mock -CommandName Add-DhcpServerv4Class
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name          = 'Test Class'
                    Type          = 'Vendor'
                    AsciiData     = 'test data'
                    AddressFamily = 'IPv4'
                    Description   = 'test class description'
                    Ensure        = 'Present'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Get-DhcpServerv4Class -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-DhcpServerv4Class -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a resource needs updating' {
        BeforeAll {
            Mock -CommandName Get-DhcpServerv4Class -MockWith {
                return @{
                    Name          = 'Test Class'
                    Type          = 'Vendor'
                    AsciiData     = 'test data'
                    Description   = 'test class description'
                    AddressFamily = 'IPv4'
                }
            }

            Mock -CommandName Set-DhcpServerv4Class
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name          = 'Test Class'
                    Type          = 'Vendor'
                    AsciiData     = 'test data'
                    AddressFamily = 'IPv4'
                    Description   = 'test class description'
                    Ensure        = 'Present'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Get-DhcpServerv4Class -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-DhcpServerv4Class -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a resource needs deleting' {
        BeforeAll {
            Mock -CommandName Get-DhcpServerv4Class -MockWith {
                return @{
                    Name          = 'Test Class'
                    Type          = 'Vendor'
                    AsciiData     = 'test data'
                    Description   = 'test class description'
                    AddressFamily = 'IPv4'
                }
            }

            Mock -CommandName Remove-DhcpServerv4Class
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name          = 'Test Class'
                    Type          = 'Vendor'
                    AsciiData     = 'test data'
                    AddressFamily = 'IPv4'
                    Description   = 'test class description'
                    Ensure        = 'Absent'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Get-DhcpServerv4Class -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-DhcpServerv4Class -Exactly -Times 1 -Scope It
        }
    }
}
