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
    $script:dscResourceName = 'DSC_xDhcpServerOptionDefinition'

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

Describe 'DSC_xDhcpServerOptionDefinition\Get-TargetResource' -Tag 'Get' {
    Context 'When the resource exists' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-DhcpServerv4OptionDefinition -MockWith {
                return @{
                    OptionId      = 22
                    Name          = 'Test name'
                    AddressFamily = 'IPv4'
                    Description   = 'Test Description'
                    Type          = 'IPv4Address'
                    VendorClass   = ''
                    MultiValued   = $false
                    DefaultValue  = '1.2.3.4'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    OptionId      = 22
                    Name          = 'Test name'
                    AddressFamily = 'IPv4'
                    Type          = 'IPv4Address'
                    VendorClass   = ''
                }

                $result = Get-TargetResource @testParams

                $result.OptionId | Should -Be $testParams.OptionId
                $result.Name | Should -Be $testParams.Name
                $result.AddressFamily | Should -Be $testParams.AddressFamily
                $result.Description | Should -Be 'Test Description'
                $result.Type | Should -Be $testParams.Type
                $result.VendorClass | Should -Be $testParams.VendorClass
                $result.MultiValued | Should -BeFalse
                $result.DefaultValue | Should -Be '1.2.3.4'
                $result.Ensure | Should -Be 'Present'
            }
        }
    }

    Context 'When the resource does not exist' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-DhcpServerv4OptionDefinition
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    OptionId      = 22
                    Name          = 'Test name'
                    AddressFamily = 'IPv4'
                    Type          = 'IPv4Address'
                    VendorClass   = ''
                }

                $result = Get-TargetResource @testParams

                $result.OptionId | Should -BeNullOrEmpty
                $result.Name | Should -BeNullOrEmpty
                $result.AddressFamily | Should -BeNullOrEmpty
                $result.Description | Should -BeNullOrEmpty
                $result.Type | Should -BeNullOrEmpty
                $result.VendorClass | Should -BeNullOrEmpty
                $result.MultiValued | Should -BeFalse
                $result.DefaultValue | Should -BeNullOrEmpty
                $result.Ensure | Should -Be 'Absent'
            }
        }
    }
}

Describe 'DSC_xDhcpServerOptionDefinition\Test-TargetResource' -Tag 'Test' {
    Context 'When the system is in the desired state' {
        Context 'When the configuration is absent' {
            BeforeAll {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        OptionId      = $null
                        Name          = $null
                        AddressFamily = $null
                        Description   = $null
                        Type          = $null
                        VendorClass   = $null
                        MultiValued   = $false
                        DefaultValue  = $null
                        Ensure        = 'Absent'
                    }
                }
            }

            It 'Should return the state as $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        OptionId      = 22
                        Name          = 'Test name'
                        VendorClass   = 'MockVendorClass'
                        Type          = 'IPv4Address'
                        AddressFamily = 'IPv4'
                        DefaultValue  = '1.2.3.4'
                        Ensure        = 'Absent'
                    }

                    $result = Test-TargetResource @testParams
                    $result | Should -BeTrue
                }
            }
        }
    }

    Context 'When the configuration is present' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    OptionId      = 22
                    Name          = 'Test name'
                    VendorClass   = 'MockVendorClass'
                    Type          = 'IPv4Address'
                    AddressFamily = 'IPv4'
                    DefaultValue  = '1.2.3.4'
                    Description   = 'Test Description'
                    MultiValued   = $true
                    Ensure        = 'Present'
                }
            }
        }

        It 'Should return the state as $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    OptionId      = 22
                    Name          = 'Test name'
                    VendorClass   = 'MockVendorClass'
                    Type          = 'IPv4Address'
                    AddressFamily = 'IPv4'
                    Description   = 'Test Description'
                    MultiValued   = $true
                    DefaultValue  = '1.2.3.4'
                    Ensure        = 'Present'
                }

                $result = Test-TargetResource @testParams
                $result | Should -BeTrue
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the configuration should be absent' {
            BeforeAll {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        OptionId      = 22
                        Name          = 'Test name'
                        AddressFamily = 'IPv4'
                        Description   = 'Test Description'
                        Type          = 'IPv4Address'
                        VendorClass   = 'MockVendorClass'
                        MultiValued   = $true
                        DefaultValue  = '1.2.3.4'
                        Ensure        = 'Present'
                    }
                }
            }

            It 'Should return the state as $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        OptionId      = 22
                        Name          = 'Test name'
                        VendorClass   = 'MockVendorClass'
                        Type          = 'IPv4Address'
                        AddressFamily = 'IPv4'
                        DefaultValue  = '1.2.3.4'
                        Ensure        = 'Absent'
                    }


                    $result = Test-TargetResource @testParams
                    $result | Should -BeFalse
                }
            }
        }

        Context 'When the configuration should be present' {
            BeforeAll {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        OptionId      = $null
                        Name          = $null
                        AddressFamily = $null
                        Description   = $null
                        Type          = $null
                        VendorClass   = $null
                        MultiValued   = $false
                        Ensure        = 'Absent'
                    }
                }
            }

            It 'Should return the state as $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        OptionId      = 22
                        Name          = 'Test name'
                        VendorClass   = 'MockVendorClass'
                        Type          = 'IPv4Address'
                        AddressFamily = 'IPv4'
                        DefaultValue  = '1.2.3.4'
                        Ensure        = 'Present'
                    }


                    $result = Test-TargetResource @testParams
                    $result | Should -BeFalse
                }
            }
        }

        Context 'When a property is not in desired state' {
            BeforeDiscovery {
                $testCases = @(
                    @{
                        Property = 'Name'
                    }
                    @{
                        Property = 'Description'
                    }
                    @{
                        Property = 'Type'
                    }
                    @{
                        Property = 'MultiValued'
                    }
                )
            }

            BeforeAll {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        OptionId      = 22
                        Name          = 'Test name'
                        AddressFamily = 'IPv4'
                        Description   = 'Test Description'
                        Type          = 'IPv4Address'
                        VendorClass   = 'MockVendorClass'
                        MultiValued   = $false
                        Ensure        = 'Present'
                    }
                }
            }

            It 'Should return the state as $false when property ''<Property>'' is not in desired state' -TestCases $testCases {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        OptionId      = 22
                        Name          = 'Test name'
                        VendorClass   = 'MockVendorClass'
                        Type          = 'IPv4Address'
                        AddressFamily = 'IPv4'
                        DefaultValue  = '1.2.3.4'
                        Ensure        = 'Present'
                    }

                    if ($Property -eq 'Type')
                    {
                        $testParams[$Property] = 'EncapsulatedData'
                    }
                    else
                    {
                        # Mock with 1 as it can be converted to string, int, and boolean.
                        $testParams[$Property] = 1
                    }

                    $result = Test-TargetResource @testParams
                    $result | Should -BeFalse
                }
            }
        }
    }
}

Describe 'DSC_xDhcpServerOptionDefinition\Set-TargetResource' -Tag 'Set' {
    Context 'When the resource does not exist' {
        Context 'When the resource needs to be created' {
            BeforeAll {
                Mock -CommandName Get-TargetResource
                Mock -CommandName Add-DhcpServerv4OptionDefinition
            }

            It 'Should call the expected mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        OptionId      = 22
                        Name          = 'Test name'
                        AddressFamily = 'IPv4'
                        Description   = 'Test Description'
                        Type          = 'IPv4Address'
                        VendorClass   = ''
                        DefaultValue  = '1.2.3.4'
                        MultiValued   = $false
                    }

                    Set-TargetResource @testParams
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Add-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the resource does exist' {
        Context 'When the resource needs to be removed' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        OptionId      = 22
                        Name          = 'Test name'
                        AddressFamily = 'IPv4'
                        Description   = 'Test Description'
                        Type          = 'IPv4Address'
                        VendorClass   = ''
                        MultiValued   = $false
                        DefaultValue  = '1.2.3.4'
                    }
                }

                Mock -CommandName Remove-DhcpServerv4OptionDefinition
            }

            It 'Should call the expected mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        OptionId      = 22
                        Name          = 'Test name'
                        AddressFamily = 'IPv4'
                        Description   = 'Test Description'
                        Type          = 'IPv4Address'
                        VendorClass   = ''
                        MultiValued   = $false
                        Ensure        = 'Absent'
                    }

                    Set-TargetResource @testParams
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Remove-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the resource needs to be re-added' {
            BeforeDiscovery {
                $testCases = @(
                    @{
                        Property = 'Type'
                        Value    = 'Byte'
                    }
                    @{
                        Property = 'MultiValued'
                        Value    = $true
                    }
                    @{
                        Property = 'VendorClass'
                        Value    = 'New VendorClass'
                    }
                )
            }

            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        OptionId      = 22
                        Name          = 'Test name'
                        AddressFamily = 'IPv4'
                        Description   = 'Test Description'
                        Type          = 'IPv4Address'
                        VendorClass   = ''
                        MultiValued   = $false
                        DefaultValue  = '1.2.3.4'
                        Ensure        = 'Present'
                    }
                }

                Mock -CommandName Remove-DhcpServerv4OptionDefinition
                Mock -CommandName Add-DhcpServerv4OptionDefinition
            }

            It 'Should call the expected mocks for ''<Property>''' -ForEach $testCases {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        OptionId      = 22
                        Name          = 'Test name'
                        AddressFamily = 'IPv4'
                        Description   = 'Test Description'
                        Type          = 'IPv4Address'
                        VendorClass   = ''
                        MultiValued   = $false
                        DefaultValue  = '1.2.3.4'
                        Ensure        = 'Present'
                    }

                    $testParams.$Property = $Value

                    Set-TargetResource @testParams
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Remove-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Add-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the resource needs to be updated' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        OptionId      = 22
                        Name          = 'Test name'
                        AddressFamily = 'IPv4'
                        Description   = 'Test Description'
                        Type          = 'IPv4Address'
                        VendorClass   = ''
                        MultiValued   = $false
                        DefaultValue  = '1.2.3.4'
                        Ensure        = 'Present'
                    }
                }

                Mock -CommandName Set-DhcpServerv4OptionDefinition
            }

            It 'Should call the expected mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        OptionId      = 22
                        Name          = 'Test name'
                        AddressFamily = 'IPv4'
                        Description   = 'New Description'
                        Type          = 'IPv4Address'
                        VendorClass   = ''
                        MultiValued   = $false
                        DefaultValue  = '1.2.3.4'
                        Ensure        = 'Present'
                    }

                    Set-TargetResource @testParams
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }
        }
    }
}
