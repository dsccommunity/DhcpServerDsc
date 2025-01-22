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
    $script:dscResourceName = 'DSC_DhcpPolicyOptionValue'

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

Describe 'DSC_DhcpPolicyOptionValue\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Get-TargetResourceHelper -ParameterFilter {
            $ApplyTo -eq 'Policy'
        } -MockWith {
            @{
                ApplyTo       = 'Policy'
                ReservedIP    = '192.168.10.100'
                UserClass     = 'AClass'
                OptionId      = 67
                Value         = @('test Value')
                VendorClass   = ''
                ScopeId       = '192.168.10.0'
                PolicyName    = 'Test Policy'
                AddressFamily = 'IPv4'
                Ensure        = 'Present'
            }
        }
    }

    It 'Should return the correct values' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $testParams = @{
                PolicyName    = 'Test Policy'
                OptionId      = 67
                ScopeId       = '192.168.10.0'
                VendorClass   = ''
                AddressFamily = 'IPv4'
            }

            $result = Get-TargetResource @testParams

            $result | Should -BeOfType [System.Collections.Hashtable]
            $result.Ensure | Should -Be 'Present'
            $result.OptionId | Should -Be 67
            $result.PolicyName | Should -Be 'Test Policy'
            $result.Value | Should -Be @('test Value')
            $result.VendorClass | Should -Be ''
            $result.AddressFamily | Should -Be 'IPv4'

            $result.ApplyTo | Should -BeNullOrEmpty
            $result.ReservedIP | Should -BeNullOrEmpty
            $result.UserClass | Should -BeNullOrEmpty
        }

        Should -Invoke -CommandName Get-TargetResourceHelper -Exactly -Times 1 -Scope It
    }
}

Describe 'DSC_DhcpPolicyOptionValue\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Test-TargetResourceHelper -MockWith {
            return $true
        }
    }

    It 'Should call the expected mocks' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $testParams = @{
                PolicyName    = 'Test Policy'
                OptionId      = 67
                Value         = @('test Value')
                ScopeId       = '192.168.10.0'
                VendorClass   = ''
                AddressFamily = 'IPv4'
            }

            $result = Test-TargetResource @testParams

            $result | Should -BeTrue
        }

        Should -Invoke -CommandName Test-TargetResourceHelper -Exactly -Times 1 -Scope It
    }
}

Describe 'DSC_DhcpPolicyOptionValue\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Set-TargetResourceHelper
    }

    It 'Should call the expected mocks' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $testParams = @{
                PolicyName    = 'Test Policy'
                OptionId      = 67
                Value         = @('test Value')
                ScopeId       = '192.168.10.0'
                VendorClass   = ''
                AddressFamily = 'IPv4'
            }

            Set-TargetResource @testParams
        }

        Should -Invoke -CommandName Set-TargetResourceHelper -Exactly -Times 1 -Scope It
    }
}
