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
    $script:dscResourceName = 'DSC_xDhcpServerScope'

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

Describe 'DSC_xDhcpServerScope\Get-TargetResource' -Tag 'Get' {
    Context 'When the resource exists' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Assert-ScopeParameter
            Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                return @{
                    ScopeID       = '192.168.1.0'
                    Name          = 'Test Scope'
                    StartRange    = '192.168.1.10'
                    EndRange      = '192.168.1.99'
                    Description   = 'Scope description'
                    SubnetMask    = '255.255.255.0'
                    LeaseDuration = New-TimeSpan -Days 8
                    State         = 'Active'
                    AddressFamily = 'IPv4'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeId      = '192.168.1.0'
                    Name         = 'Test Scope'
                    IPStartRange = '192.168.1.10'
                    IPEndRange   = '192.168.1.99'
                    SubnetMask   = '255.255.255.0'
                }

                $result = Get-TargetResource @testParams

                $result.Name | Should -Be $testParams.Name
                $result.IPStartRange | Should -Be $testParams.IPStartRange
                $result.IPEndRange | Should -Be $testParams.IPEndRange
                $result.SubnetMask | Should -Be $testParams.SubnetMask
                $result.Description | Should -Be 'Scope description'
                $result.LeaseDuration | Should -Be (New-TimeSpan -Days 8)
                $result.State | Should -Be 'Active'
                $result.AddressFamily | Should -Be 'Ipv4'
                $result.Ensure | Should -Be Present
            }
        }
    }

    Context 'When the resource does not exist' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Assert-ScopeParameter
            Mock -CommandName Get-DhcpServerv4Scope
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeId      = '192.168.1.0'
                    Name         = 'Test Scope'
                    IPStartRange = '192.168.1.10'
                    IPEndRange   = '192.168.1.99'
                    SubnetMask   = '255.255.255.0'
                }

                $result = Get-TargetResource @testParams

                $result.Name | Should -BeNullOrEmpty
                $result.IPStartRange | Should -BeNullOrEmpty
                $result.IPEndRange | Should -BeNullOrEmpty
                $result.SubnetMask | Should -BeNullOrEmpty
                $result.Description | Should -BeNullOrEmpty
                $result.LeaseDuration | Should -BeNullOrEmpty
                $result.State | Should -BeNullOrEmpty
                $result.AddressFamily | Should -Be 'IPv4'
                $result.Ensure | Should -Be Absent
            }
        }
    }
}

Describe 'DSC_xDhcpServerScope\Test-TargetResource' -Tag 'Test' {
    Context 'When the resource is in the desired state' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Assert-ScopeParameter
            Mock -CommandName Update-ResourceProperties -MockWith {
                return $true
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeId       = '192.168.1.0'
                    Name          = 'Test Scope'
                    IPStartRange  = '192.168.1.10'
                    IPEndRange    = '192.168.1.99'
                    SubnetMask    = '255.255.255.0'
                    AddressFamily = 'IPv4'
                    Debug         = $true
                }

                Test-TargetResource @testParams | Should -BeTrue
            }
        }
    }

    Context 'When the resource is not in the desired state' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Assert-ScopeParameter
            Mock -CommandName Update-ResourceProperties -MockWith {
                return $false
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeId       = '192.168.1.0'
                    Name          = 'Test Scope'
                    IPStartRange  = '192.168.1.10'
                    IPEndRange    = '192.168.1.99'
                    SubnetMask    = '255.255.255.0'
                    AddressFamily = 'IPv4'
                    Debug         = $true
                }

                Test-TargetResource @testParams | Should -BeFalse
            }
        }
    }
}

Describe 'DSC_xDhcpServerScope\Set-TargetResource' -Tag 'Set' {
    Context 'When the resource should be updated' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Assert-ScopeParameter
            Mock -CommandName Update-ResourceProperties
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeId       = '192.168.1.0'
                    Name          = 'Test Scope'
                    IPStartRange  = '192.168.1.10'
                    IPEndRange    = '192.168.1.99'
                    SubnetMask    = '255.255.255.0'
                    AddressFamily = 'IPv4'
                    Debug         = $true
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Assert-Module -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-ScopeParameter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Update-ResourceProperties -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_xDhcpServerScope\Update-ResourceProperties' -Tag 'Helper' {
    Context 'When testing DSC resource required properties' {
        Context 'When the resource is present and correct' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return @{
                        ScopeID       = '192.168.1.0'
                        Name          = 'Test Scope'
                        StartRange    = '192.168.1.10'
                        EndRange      = '192.168.1.99'
                        Description   = 'Scope description'
                        SubnetMask    = '255.255.255.0'
                        LeaseDuration = New-TimeSpan -Days 8
                        State         = 'Active'
                        AddressFamily = 'IPv4'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId      = '192.168.1.0'
                        Name         = 'Test Scope'
                        IPStartRange = '192.168.1.10'
                        IPEndRange   = '192.168.1.99'
                        SubnetMask   = '255.255.255.0'
                        Apply        = $false
                    }

                    Update-ResourceProperties @testParams | Should -BeTrue
                }
            }
        }

        Context 'When the resource is absent and correct' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Scope
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId      = '192.168.1.0'
                        Name         = 'Test Scope'
                        IPStartRange = '192.168.1.10'
                        IPEndRange   = '192.168.1.99'
                        SubnetMask   = '255.255.255.0'
                        Ensure       = 'Absent'
                        Apply        = $false
                    }

                    Update-ResourceProperties @testParams | Should -BeTrue
                }
            }
        }

        Context 'When the resource is present and incorrect' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return @{
                        ScopeID       = '192.168.1.0'
                        Name          = 'Test Scope'
                        StartRange    = '192.168.1.10'
                        EndRange      = '192.168.1.99'
                        Description   = 'Scope description'
                        SubnetMask    = '255.255.255.0'
                        LeaseDuration = New-TimeSpan -Days 8
                        State         = 'Active'
                        AddressFamily = 'IPv4'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId      = '192.168.1.0'
                        Name         = 'Test Scope'
                        IPStartRange = '192.168.1.10'
                        IPEndRange   = '192.168.1.99'
                        SubnetMask   = '255.255.255.0'
                        Ensure       = 'Absent'
                        Apply        = $false
                    }

                    Update-ResourceProperties @testParams | Should -BeFalse
                }
            }
        }

        Context 'When the resource is absent and incorrect' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Scope
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId      = '192.168.1.0'
                        Name         = 'Test Scope'
                        IPStartRange = '192.168.1.10'
                        IPEndRange   = '192.168.1.99'
                        SubnetMask   = '255.255.255.0'
                        Ensure       = 'Present'
                        Apply        = $false
                    }

                    Update-ResourceProperties @testParams | Should -BeFalse
                }
            }
        }

        Context 'When an individual property is incorrect' {
            BeforeDiscovery {
                $testCases = @(
                    @{
                        Parameter = 'Name'
                        Value     = 'New Test Scope'
                    }
                    @{
                        Parameter = 'IPStartRange'
                        Value     = '192.168.1.20'
                    }
                    @{
                        Parameter = 'IPEndRange'
                        Value     = '192.168.1.199'
                    }
                    @{
                        Parameter = 'SubnetMask'
                        Value     = '255.255.254.0'
                    }
                )
            }

            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return @{
                        ScopeID       = '192.168.1.0'
                        Name          = 'Test Scope'
                        StartRange    = '192.168.1.10'
                        EndRange      = '192.168.1.99'
                        Description   = 'Scope description'
                        SubnetMask    = '255.255.255.0'
                        LeaseDuration = New-TimeSpan -Days 8
                        State         = 'Active'
                        AddressFamily = 'IPv4'
                    }
                }
            }

            It 'Should return the correct result for property ''<Parameter>''' -ForEach $testCases {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId      = '192.168.1.0'
                        Name         = 'Test Scope'
                        IPStartRange = '192.168.1.10'
                        IPEndRange   = '192.168.1.99'
                        SubnetMask   = '255.255.255.0'
                        Apply        = $false
                    }

                    $testParams.$Parameter = $Value

                    Update-ResourceProperties @testParams | Should -BeFalse
                }
            }
        }
    }

    Context 'When testing DSC resource optional properties' {
        Context 'When the resource is present and correct' {
            BeforeDiscovery {
                $testCases = @(
                    @{
                        Parameter = 'Description'
                        Value     = 'Scope description'
                    }
                    @{
                        Parameter = 'LeaseDuration'
                        Value     = New-TimeSpan -Days 8
                    }
                    @{
                        Parameter = 'State'
                        Value     = 'Active'
                    }
                )
            }

            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return @{
                        ScopeID       = '192.168.1.0'
                        Name          = 'Test Scope'
                        StartRange    = '192.168.1.10'
                        EndRange      = '192.168.1.99'
                        Description   = 'Scope description'
                        SubnetMask    = '255.255.255.0'
                        LeaseDuration = New-TimeSpan -Days 8
                        State         = 'Active'
                        AddressFamily = 'IPv4'
                    }
                }
            }

            It 'Should return the correct result for property ''<Parameter>''' -ForEach $testCases {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId      = '192.168.1.0'
                        Name         = 'Test Scope'
                        IPStartRange = '192.168.1.10'
                        IPEndRange   = '192.168.1.99'
                        SubnetMask   = '255.255.255.0'
                        Apply        = $false
                        $Parameter   = $Value
                    }

                    Update-ResourceProperties @testParams | Should -BeTrue
                }
            }
        }

        Context 'When the resource is present and incorrect' {
            BeforeDiscovery {
                $testCases = @(
                    @{
                        Parameter = 'Description'
                        Value     = 'New Scope description'
                    }
                    @{
                        Parameter = 'LeaseDuration'
                        Value     = New-TimeSpan -Days 10
                    }
                    @{
                        Parameter = 'State'
                        Value     = 'Inactive'
                    }
                )
            }

            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return @{
                        ScopeID       = '192.168.1.0'
                        Name          = 'Test Scope'
                        StartRange    = '192.168.1.10'
                        EndRange      = '192.168.1.99'
                        Description   = 'Scope description'
                        SubnetMask    = '255.255.255.0'
                        LeaseDuration = New-TimeSpan -Days 8
                        State         = 'Active'
                        AddressFamily = 'IPv4'
                    }
                }
            }

            It 'Should return the correct result for property ''<Parameter>''' -ForEach $testCases {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId      = '192.168.1.0'
                        Name         = 'Test Scope'
                        IPStartRange = '192.168.1.10'
                        IPEndRange   = '192.168.1.99'
                        SubnetMask   = '255.255.255.0'
                        Apply        = $false
                        $Parameter   = $Value
                    }

                    Update-ResourceProperties @testParams | Should -BeFalse
                }
            }
        }
    }

    Context 'When setting the DSC resource with required properties' {
        Context 'When the resource is present' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return @{
                        ScopeID       = '192.168.1.0'
                        Name          = 'Test Scope'
                        StartRange    = '192.168.1.10'
                        EndRange      = '192.168.1.99'
                        Description   = 'Scope description'
                        SubnetMask    = '255.255.255.0'
                        LeaseDuration = New-TimeSpan -Days 8
                        State         = 'Active'
                        AddressFamily = 'IPv4'
                    }
                }

                Mock -CommandName Add-DhcpServerv4Scope
                Mock -CommandName Remove-DhcpServerv4Scope
                Mock -CommandName Set-DhcpServerv4Scope
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId      = '192.168.1.0'
                        Name         = 'Test Scope'
                        IPStartRange = '192.168.1.10'
                        IPEndRange   = '192.168.1.99'
                        SubnetMask   = '255.255.255.0'
                        Apply        = $true
                    }

                    Update-ResourceProperties @testParams
                }

                Should -Invoke -CommandName Get-DhcpServerv4Scope -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Add-DhcpServerv4Scope -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Remove-DhcpServerv4Scope -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Set-DhcpServerv4Scope -Exactly -Times 0 -Scope It
            }
        }

        Context 'When the resource is present and individual properties are incorrect' {
            BeforeDiscovery {
                $testCases = @(
                    @{
                        Parameter   = 'Name'
                        Value       = 'New Test Scope'
                        AddCount    = 0
                        RemoveCount = 0
                        SetCount    = 1
                    }
                    @{
                        Parameter   = 'IPStartRange'
                        Value       = '192.168.1.20'
                        AddCount    = 0
                        RemoveCount = 0
                        SetCount    = 1
                    }
                    @{
                        Parameter   = 'IPEndRange'
                        Value       = '192.168.1.199'
                        AddCount    = 0
                        RemoveCount = 0
                        SetCount    = 1
                    }
                    @{
                        Parameter   = 'SubnetMask'
                        Value       = '255.255.254.0'
                        AddCount    = 1
                        RemoveCount = 1
                        SetCount    = 0
                    }
                    @{
                        Parameter   = 'Description'
                        Value       = 'New Scope description'
                        AddCount    = 0
                        RemoveCount = 0
                        SetCount    = 1
                    }
                    @{
                        Parameter   = 'LeaseDuration'
                        Value       = New-TimeSpan -Days 10
                        AddCount    = 0
                        RemoveCount = 0
                        SetCount    = 1
                    }
                    @{
                        Parameter   = 'State'
                        Value       = 'Inactive'
                        AddCount    = 0
                        RemoveCount = 0
                        SetCount    = 1
                    }
                )
            }

            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return @{
                        ScopeID       = '192.168.1.0'
                        Name          = 'Test Scope'
                        StartRange    = '192.168.1.10'
                        EndRange      = '192.168.1.99'
                        Description   = 'Scope description'
                        SubnetMask    = '255.255.255.0'
                        LeaseDuration = New-TimeSpan -Days 8
                        State         = 'Active'
                        AddressFamily = 'IPv4'
                    }
                }

                Mock -CommandName Add-DhcpServerv4Scope
                Mock -CommandName Remove-DhcpServerv4Scope
                Mock -CommandName Set-DhcpServerv4Scope
            }

            It 'Should call the correct mocks for property ''<Parameter>''' -ForEach $testCases {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId      = '192.168.1.0'
                        Name         = 'Test Scope'
                        IPStartRange = '192.168.1.10'
                        IPEndRange   = '192.168.1.99'
                        SubnetMask   = '255.255.255.0'
                        Apply        = $true
                    }

                    $testParams.$Parameter = $Value

                    Update-ResourceProperties @testParams
                }

                Should -Invoke -CommandName Get-DhcpServerv4Scope -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Add-DhcpServerv4Scope -Exactly -Times $AddCount -Scope It
                Should -Invoke -CommandName Remove-DhcpServerv4Scope -Exactly -Times $RemoveCount -Scope It
                Should -Invoke -CommandName Set-DhcpServerv4Scope -Exactly -Times $SetCount -Scope It
            }
        }

        Context 'When the resource should be removed' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return @{
                        ScopeID       = '192.168.1.0'
                        Name          = 'Test Scope'
                        StartRange    = '192.168.1.10'
                        EndRange      = '192.168.1.99'
                        Description   = 'Scope description'
                        SubnetMask    = '255.255.255.0'
                        LeaseDuration = New-TimeSpan -Days 8
                        State         = 'Active'
                        AddressFamily = 'IPv4'
                    }
                }

                Mock -CommandName Add-DhcpServerv4Scope
                Mock -CommandName Remove-DhcpServerv4Scope
                Mock -CommandName Set-DhcpServerv4Scope
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId      = '192.168.1.0'
                        Name         = 'Test Scope'
                        IPStartRange = '192.168.1.10'
                        IPEndRange   = '192.168.1.99'
                        SubnetMask   = '255.255.255.0'
                        Ensure       = 'Absent'
                        Apply        = $true
                    }

                    Update-ResourceProperties @testParams
                }

                Should -Invoke -CommandName Get-DhcpServerv4Scope -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Add-DhcpServerv4Scope -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Remove-DhcpServerv4Scope -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-DhcpServerv4Scope -Exactly -Times 0 -Scope It
            }
        }

        Context 'When the resource does not exist' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Scope
                Mock -CommandName Add-DhcpServerv4Scope
                Mock -CommandName Remove-DhcpServerv4Scope
                Mock -CommandName Set-DhcpServerv4Scope
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId       = '192.168.1.0'
                        Name          = 'Test Scope'
                        IPStartRange  = '192.168.1.10'
                        IPEndRange    = '192.168.1.99'
                        SubnetMask    = '255.255.255.0'
                        LeaseDuration = New-TimeSpan -Days 8
                        State         = 'Active'
                        Apply         = $true
                    }

                    Update-ResourceProperties @testParams
                }

                Should -Invoke -CommandName Get-DhcpServerv4Scope -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Add-DhcpServerv4Scope -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Remove-DhcpServerv4Scope -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Set-DhcpServerv4Scope -Exactly -Times 0 -Scope It
            }
        }

        Context 'When updating the Subnet Mask fails' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return @{
                        ScopeID       = '192.168.1.0'
                        Name          = 'Test Scope'
                        StartRange    = '192.168.1.10'
                        EndRange      = '192.168.1.99'
                        Description   = 'Scope description'
                        SubnetMask    = '255.255.255.0'
                        LeaseDuration = New-TimeSpan -Days 8
                        State         = 'Active'
                        AddressFamily = 'IPv4'
                    }
                }

                Mock -CommandName Add-DhcpServerv4Scope
                Mock -CommandName Remove-DhcpServerv4Scope -MockWith { throw }
                Mock -CommandName Set-DhcpServerv4Scope
            }

            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId      = '192.168.1.0'
                        Name         = 'Test Scope'
                        IPStartRange = '192.168.1.10'
                        IPEndRange   = '192.168.1.99'
                        SubnetMask   = '255.255.254.0'
                        Apply        = $true
                    }

                    { Update-ResourceProperties @testParams } | Should -Throw
                }

                Should -Invoke -CommandName Get-DhcpServerv4Scope -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Add-DhcpServerv4Scope -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Remove-DhcpServerv4Scope -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-DhcpServerv4Scope -Exactly -Times 0 -Scope It
            }

        }

        Context 'When creating the resource fails' {
            BeforeAll {
                Mock -CommandName Get-DhcpServerv4Scope
                Mock -CommandName Add-DhcpServerv4Scope -MockWith { throw }
                Mock -CommandName Remove-DhcpServerv4Scope
                Mock -CommandName Set-DhcpServerv4Scope
            }

            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        ScopeId      = '192.168.1.0'
                        Name         = 'Test Scope'
                        IPStartRange = '192.168.1.10'
                        IPEndRange   = '192.168.1.99'
                        SubnetMask   = '255.255.254.0'
                        Apply        = $true
                    }

                    { Update-ResourceProperties @testParams } | Should -Throw
                }

                Should -Invoke -CommandName Get-DhcpServerv4Scope -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Add-DhcpServerv4Scope -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Remove-DhcpServerv4Scope -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Set-DhcpServerv4Scope -Exactly -Times 0 -Scope It
            }

        }
    }
}
