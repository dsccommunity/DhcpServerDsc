$script:dscModuleName = 'DhcpServerDsc'
$script:dscResourceName = 'DSC_DhcpPolicyOptionValue'

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

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $policyName = 'Test Policy'
        $optionId = 67
        $value = @('test Value')
        $scopeId = '10.1.1.0'
        $vendorClass = ''
        $addressFamily = 'IPv4'
        $ensure = 'Present'

        $testParams = @{
            PolicyName    = $policyName
            OptionId      = $optionId
            ScopeId       = $scopeId
            VendorClass   = $vendorClass
            AddressFamily = $addressFamily
            Verbose       = $true
        }

        $getFakeDhcpPolicyv4OptionValue = {
            return @{
                PolicyName    = $policyName
                OptionId      = $optionId
                Value         = $value
                ScopeId       = $scopeId
                VendorClass   = $vendorClass
                AddressFamily = $addressFamily
            }
        }

        $getFakeDhcpPolicyv4OptionValueID168 = {
            return @{
                PolicyName    = $policyName
                OptionId      = 168
                Value         = $value
                ScopeId       = $scopeId
                VendorClass   = $vendorClass
                AddressFamily = $addressFamily
            }
        }

        $getFakeDhcpPolicyv4OptionValueDifferentValue = {
            return @{
                PolicyName    = $policyName
                OptionId      = $optionId
                Value         = @('DifferentValue')
                ScopeId       = $scopeId
                VendorClass   = $vendorClass
                AddressFamily = $addressFamily
            }
        }

        Describe 'DSC_DhcpPolicyOptionValue\Get-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module -ModuleName 'DhcpServerDsc.OptionValueHelper'
            }

            It 'Should call "Assert-Module" to ensure "DHCPServer" module is available' {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith $GetFakeDhcpPolicyv4OptionValue -ModuleName 'DhcpServerDsc.OptionValueHelper'

                $result = Get-TargetResource @testParams

                Assert-MockCalled -CommandName Assert-Module -ModuleName 'DhcpServerDsc.OptionValueHelper' -Exactly -Times 1 -Scope It
            }

            It 'Returns a "System.Collections.Hashtable" object type' {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith $GetFakeDhcpPolicyv4OptionValue -ModuleName 'DhcpServerDsc.OptionValueHelper'

                $result = Get-TargetResource @testParams

                $result | Should -BeOfType [System.Collections.Hashtable]
            }

            It 'Returns "Absent" when the option value does not exist' {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith { return $null } -ModuleName 'DhcpServerDsc.OptionValueHelper'

                $result = Get-TargetResource @testParams
                $result.Ensure | Should -Be 'Absent'
            }

            It 'Returns all correct values' {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith $getFakeDhcpPolicyv4OptionValueDifferentValue -ModuleName 'DhcpServerDsc.OptionValueHelper'

                $result = Get-TargetResource @testParams

                $result.Ensure | Should -Be $ensure
                $result.OptionId | Should -Be $optionId
                $result.PolicyName | Should -Be $policyName
                $result.Value | Should -Be @('DifferentValue')
                $result.VendorClass | Should -Be $vendorClass
                $result.AddressFamily | Should -Be $addressFamily
            }

            It 'Returns the properties as $null when the option does not exist' {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith { return $null } -ModuleName 'DhcpServerDsc.OptionValueHelper'

                $result = Get-TargetResource @testParams

                $result.Ensure | Should -Be 'Absent'
                $result.OptionId | Should -Be $null
                $result.PolicyName | Should -Be $null
                $result.Value | Should -Be $null
                $result.VendorClass | Should -Be $null
                $result.AddressFamily | Should -Be $null
            }
        }


        Describe 'DSC_DhcpPolicyOptionValue\Test-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module -ModuleName 'DhcpServerDsc.OptionValueHelper'
            }

            It 'Returns a "System.Boolean" object type' {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith $GetFakeDhcpPolicyv4OptionValue -ModuleName 'DhcpServerDsc.OptionValueHelper'

                $result = Test-TargetResource @testParams -Ensure 'Present' -Value $value

                $result | Should -BeOfType [System.Boolean]
            }

            It 'Returns $true when the option exists and Ensure = Present' {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith $GetFakeDhcpPolicyv4OptionValue -ModuleName 'DhcpServerDsc.OptionValueHelper'

                $result = Test-TargetResource @testParams -Ensure 'Present' -Value $value

                $result | Should -Be $true
            }

            It 'Returns $false when the option does not exist and Ensure = Present' {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith { return $null } -ModuleName 'DhcpServerDsc.OptionValueHelper'

                $result = Test-TargetResource @testParams -Ensure 'Present' -Value $value

                $result | Should -Be $false
            }

            It 'Returns $false when the option exists and Ensure = Absent ' {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith $GetFakeDhcpPolicyv4OptionValue -ModuleName 'DhcpServerDsc.OptionValueHelper'

                $result = Test-TargetResource @testParams -Ensure 'Absent' -Value $value

                $result | Should -Be $false
            }
        }

        Describe 'DSC_DhcpPolicyOptionValue\Set-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module -ModuleName 'DhcpServerDsc.OptionValueHelper'
            }

            Mock -CommandName Remove-DhcpServerv4OptionValue -ModuleName 'DhcpServerDsc.OptionValueHelper'
            Mock -CommandName Set-DhcpServerv4OptionValue -ModuleName 'DhcpServerDsc.OptionValueHelper'

            It 'Should call "Set-DhcpServerv4OptionValue" when "Ensure" = "Present" and definition does not exist' {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith { return $null } -ModuleName 'DhcpServerDsc.OptionValueHelper'

                Set-TargetResource @testParams -Ensure 'Present' -Value $value

                Assert-MockCalled -CommandName Set-DhcpServerv4OptionValue -ModuleName 'DhcpServerDsc.OptionValueHelper' -Exactly -Times 1 -Scope It
            }

            It 'Should call "Remove-DhcpServerv4OptionValue" when "Ensure" = "Absent" and Definition does exist' {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith $GetFakeDhcpPolicyv4OptionValue -ModuleName 'DhcpServerDsc.OptionValueHelper'

                Set-TargetResource @testParams -Ensure 'Absent' -Value $value

                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionValue -ModuleName 'DhcpServerDsc.OptionValueHelper' -Exactly -Times 1 -Scope It
            }

            It 'Should call "Set-DhcpServerv4OptionValue" when "Ensure" = "Present" and option value is different' {
                Mock -CommandName Get-DhcpServerv4OptionValue -MockWith $getFakeDhcpPolicyv4OptionValueDifferentValue -ModuleName 'DhcpServerDsc.OptionValueHelper'

                Set-TargetResource @testParams -Ensure 'Present' -Value $value

                Assert-MockCalled -CommandName Set-DhcpServerv4OptionValue -ModuleName 'DhcpServerDsc.OptionValueHelper' -Exactly -Times 1 -Scope It
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
