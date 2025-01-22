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


# $policyName = 'Test Policy'
# $optionId = 67
# $value = @('test Value')
# $scopeId = '10.1.1.0'
# $vendorClass = ''
# $addressFamily = 'IPv4'
# $ensure = 'Present'

# $testParams = @{
#     PolicyName    = $policyName
#     OptionId      = $optionId
#     ScopeId       = $scopeId
#     VendorClass   = $vendorClass
#     AddressFamily = $addressFamily
#     Verbose       = $true
# }

# $getFakeDhcpPolicyv4OptionValue = {
#     return @{
#         PolicyName    = $policyName
#         OptionId      = $optionId
#         Value         = $value
#         ScopeId       = $scopeId
#         VendorClass   = $vendorClass
#         AddressFamily = $addressFamily
#     }
# }

# $getFakeDhcpPolicyv4OptionValueID168 = {
#     return @{
#         PolicyName    = $policyName
#         OptionId      = 168
#         Value         = $value
#         ScopeId       = $scopeId
#         VendorClass   = $vendorClass
#         AddressFamily = $addressFamily
#     }
# }

# $getFakeDhcpPolicyv4OptionValueDifferentValue = {
#     return @{
#         PolicyName    = $policyName
#         OptionId      = $optionId
#         Value         = @('DifferentValue')
#         ScopeId       = $scopeId
#         VendorClass   = $vendorClass
#         AddressFamily = $addressFamily
#     }
# }

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


    It 'Returns all correct values' {
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


# Describe 'DSC_DhcpPolicyOptionValue\Test-TargetResource' {
#     BeforeAll {
#         Mock -CommandName Assert-Module
#     }

#     It 'Returns a "System.Boolean" object type' {
#         Mock -CommandName Get-DhcpServerv4OptionValue -MockWith $GetFakeDhcpPolicyv4OptionValue

#         $result = Test-TargetResource @testParams -Ensure 'Present' -Value $value

#         $result | Should -BeOfType [System.Boolean]
#     }

#     It 'Returns $true when the option exists and Ensure = Present' {
#         Mock -CommandName Get-DhcpServerv4OptionValue -MockWith $GetFakeDhcpPolicyv4OptionValue

#         $result = Test-TargetResource @testParams -Ensure 'Present' -Value $value

#         $result | Should -Be $true
#     }

#     It 'Returns $false when the option does not exist and Ensure = Present' {
#         Mock -CommandName Get-DhcpServerv4OptionValue -MockWith { return $null }

#         $result = Test-TargetResource @testParams -Ensure 'Present' -Value $value

#         $result | Should -Be $false
#     }

#     It 'Returns $false when the option exists and Ensure = Absent ' {
#         Mock -CommandName Get-DhcpServerv4OptionValue -MockWith $GetFakeDhcpPolicyv4OptionValue

#         $result = Test-TargetResource @testParams -Ensure 'Absent' -Value $value

#         $result | Should -Be $false
#     }
# }

# Describe 'DSC_DhcpPolicyOptionValue\Set-TargetResource' {
#     BeforeAll {
#         Mock -CommandName Assert-Module
#     }

#     Mock -CommandName Remove-DhcpServerv4OptionValue
#     Mock -CommandName Set-DhcpServerv4OptionValue

#     It 'Should call "Set-DhcpServerv4OptionValue" when "Ensure" = "Present" and definition does not exist' {
#         Mock -CommandName Get-DhcpServerv4OptionValue -MockWith { return $null }

#         Set-TargetResource @testParams -Ensure 'Present' -Value $value

#         Assert-MockCalled -CommandName Set-DhcpServerv4OptionValue -Exactly -Times 1 -Scope It
#     }

#     It 'Should call "Remove-DhcpServerv4OptionValue" when "Ensure" = "Absent" and Definition does exist' {
#         Mock -CommandName Get-DhcpServerv4OptionValue -MockWith $GetFakeDhcpPolicyv4OptionValue

#         Set-TargetResource @testParams -Ensure 'Absent' -Value $value

#         Assert-MockCalled -CommandName Remove-DhcpServerv4OptionValue -Exactly -Times 1 -Scope It
#     }

#     It 'Should call "Set-DhcpServerv4OptionValue" when "Ensure" = "Present" and option value is different' {
#         Mock -CommandName Get-DhcpServerv4OptionValue -MockWith $getFakeDhcpPolicyv4OptionValueDifferentValue

#         Set-TargetResource @testParams -Ensure 'Present' -Value $value

#         Assert-MockCalled -CommandName Set-DhcpServerv4OptionValue -Exactly -Times 1 -Scope It
#     }
# }
