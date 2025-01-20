$script:dscModuleName = 'DhcpServerDsc'
$script:dscResourceName = 'MSFT_xDhcpServerScope'

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
        $testScopeName = 'Test Scope'
        $testScopeID = '192.168.1.0'
        $testIPStartRange = '192.168.1.10'
        $testIPEndRange = '192.168.1.99'
        $testSubnetMask = '255.255.255.0'
        $testState = 'Active'
        $testLeaseDuration = New-TimeSpan -Days 8
        $testDescription = 'Scope description'
        $testAddressFamily = 'IPv4'

        $testParams = @{
            ScopeId      = $testScopeID
            Name         = $testScopeName
            IPStartRange = $testIPStartRange
            IPEndRange   = $testIPEndRange
            SubnetMask   = $testSubnetMask
            Verbose      = $true
        }

        $fakeDhcpServerv4Scope = [PSCustomObject] @{
            ScopeID       = $testScopeID
            Name          = $testScopeName
            StartRange    = $testIPStartRange
            EndRange      = $testIPEndRange
            Description   = $testDescription
            SubnetMask    = $testSubnetMask
            LeaseDuration = $testLeaseDuration
            State         = $testState
            AddressFamily = $testAddressFamily
        }

        Describe 'MSFT_xDhcpServerScope\Get-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module
            }

            Mock -CommandName Assert-ScopeParameter -ParameterFilter {
                $ScopeId -eq $testScopeID -and
                $SubnetMask -eq $testSubnetMask -and
                $IPStartRange -eq $testIPStartRange -and
                $IPEndRange -eq $testIPEndRange -and
                $AddressFamily -eq $testAddressFamily
            }

            It 'Should call "Assert-Module" to ensure "DHCPServer" module is available' {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return $fakeDhcpServerv4Scope
                }

                { Get-TargetResource @testParams } | Should -Not -Throw

                Assert-MockCalled -CommandName Assert-Module -ParameterFilter {
                    $ModuleName -eq 'DHCPServer'
                } -Exactly -Times 1 -Scope It
            }

            It 'Should call "Assert-ScopeParameter" to ensure parameters passed are correct' {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return $fakeDhcpServerv4Scope
                }

                $result = Get-TargetResource @testParams

                Assert-MockCalled -CommandName Assert-Module -Exactly -Times 1 -Scope It
            }

            It 'Should return a "System.Collections.Hashtable" object type' {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return $fakeDhcpServerv4Scope
                }

                Get-TargetResource @testParams | Should -BeOfType System.Collections.Hashtable
            }

            It 'Should return all information about existing scope with specified ScopeId' {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return $fakeDhcpServerv4Scope
                }

                $result = Get-TargetResource @testParams

                $result.Name | Should -Be $testScopeName
                $result.IPStartRange | Should -Be $testIPStartRange
                $result.IPEndRange | Should -Be $testIPEndRange
                $result.SubnetMask | Should -Be $testSubnetMask
                $result.Description | Should -Be $testDescription
                $result.LeaseDuration | Should -Be $testLeaseDuration
                $result.State | Should -Be $testState
                $result.AddressFamily | Should -Be $testAddressFamily
                $result.Ensure | Should -Be Present
            }

            It 'Should return basic information about missing scope with specified ScopeId' {
                Mock -CommandName Get-DhcpServerv4Scope

                $result = Get-TargetResource @testParams

                $result.Name | Should -BeNullOrEmpty
                $result.IPStartRange | Should -BeNullOrEmpty
                $result.IPEndRange | Should -BeNullOrEmpty
                $result.SubnetMask | Should -BeNullOrEmpty
                $result.Description | Should -BeNullOrEmpty
                $result.LeaseDuration | Should -BeNullOrEmpty
                $result.State | Should -BeNullOrEmpty
                $result.AddressFamily | Should -Be $testAddressFamily
                $result.Ensure | Should -Be Absent
            }
        }

        Describe 'MSFT_xDhcpServerScope\Test-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module
            }

            It 'Should return a "System.Boolean" object type' {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return $fakeDhcpServerv4Scope
                }

                Test-TargetResource @testParams | Should -BeOfType System.Boolean
            }

            It 'Should pass when all parameters are correct' {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return $fakeDhcpServerv4Scope
                }

                Test-TargetResource @testParams | Should -BeTrue
            }

            It 'Should pass when optional <Parameter> parameter is correct' {
                param
                (
                    [Parameter()]
                    $Parameter,

                    [Parameter()]
                    $Value
                )

                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return $fakeDhcpServerv4Scope
                }

                $optionalParameters = @{
                    $Parameter = $Value
                }

                Test-TargetResource @testParams @optionalParameters | Should -BeTrue
            } -TestCases @(
                @{
                    Parameter = 'Description'
                    Value     = $testDescription
                }
                @{
                    Parameter = 'LeaseDuration'
                    Value     = $testLeaseDuration.ToString()
                }
                @{
                    Parameter = 'State'
                    Value     = $testState
                }
            )

            It 'Should pass when "Ensure" = "Absent" and scope does not exist' {
                Mock -CommandName Get-DhcpServerv4Scope

                Test-TargetResource @testParams -Ensure 'Absent' | Should -BeTrue
            }

            It 'Should fail when <parameter> parameter is incorrect' {
                param
                (
                    [Parameter()]
                    $Parameter,

                    [Parameter()]
                    $Value
                )

                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return $fakeDhcpServerv4Scope
                }

                $testNameParams = $testParams.Clone()
                $testNameParams[$Parameter] = $Value

                Test-TargetResource @testNameParams | Should -BeFalse
            } -TestCases @(
                @{
                    Parameter = 'Name'
                    Value     = 'IncorrectName'
                }
                @{
                    Parameter = 'IPStartRange'
                    Value     = '192.168.1.1'
                }
                @{
                    Parameter = 'IPEndRange'
                    Value     = '192.168.1.254'
                }
                @{
                    Parameter = 'SubnetMask'
                    Value     = '255.255.255.128'
                }
                @{
                    Parameter = 'Description'
                    Value     = 'Wrong description'
                }
                @{
                    Parameter = 'LeaseDuration'
                    Value     = '08:00:00'
                }
                @{
                    Parameter = 'State'
                    Value     = 'Inactive'
                }
                @{
                    Parameter = 'Ensure'
                    Value     = 'Absent'
                }
            )
        }

        Describe 'MSFT_xDhcpServerScope\Set-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module
            }

            It 'Should call "Add-DhcpServerv4Scope" when "Ensure" = "Present" and scope does not exist' {
                Mock -CommandName Get-DhcpServerv4Scope
                Mock -CommandName Add-DhcpServerv4Scope

                Set-TargetResource @testParams

                Assert-MockCalled -CommandName Add-DhcpServerv4Scope -ParameterFilter {
                    $StartRange -eq $testIPStartRange -and
                    $EndRange -eq $testIPEndRange -and
                    $SubnetMask -eq $testSubnetMask -and
                    $Name -eq $testScopeName
                } -Exactly -Times 1 -Scope It
            }

            It 'Should call "Remove-DhcpServerv4Scope" when "Ensure" = "Absent" and scope does exist' {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return $fakeDhcpServerv4Scope
                }

                Mock -CommandName Remove-DhcpServerv4Scope

                Set-TargetResource @testParams -Ensure 'Absent'

                Assert-MockCalled -CommandName Remove-DhcpServerv4Scope -ParameterFilter {
                    $ScopeId -eq $testScopeID
                } -Exactly -Times 1 -Scope It
            }

            It 'Should call "Set-DhcpServerv4Scope" when "Ensure" = "Present" and scope does exist' {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return $fakeDhcpServerv4Scope
                }

                Mock -CommandName Set-DhcpServerv4Scope

                Set-TargetResource @testParams -LeaseDuration '08:00:00'

                Assert-MockCalled -CommandName Set-DhcpServerv4Scope -ParameterFilter {
                    $ScopeId -eq $testScopeID -and
                    $LeaseDuration -eq (New-TimeSpan -Hours 8)
                } -Exactly -Times 1 -Scope It
            }

            It 'Should call "Remove-DhcpServerv4Scope" when "Ensure" = "Present", scope does exist but "SubnetMask" is incorrect' {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    return $fakeDhcpServerv4Scope
                }

                Mock -CommandName Remove-DhcpServerv4Scope
                Mock -CommandName Set-DhcpServerv4Scope

                $testSubnetMaskParams = $testParams.Clone()
                $testSubnetMaskParams['SubnetMask'] = '255.255.255.128'

                Set-TargetResource @testSubnetMaskParams

                Assert-MockCalled -CommandName Remove-DhcpServerv4Scope -ParameterFilter {
                    $ScopeId -eq $testScopeID
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Add-DhcpServerv4Scope -ParameterFilter {
                    $StartRange -eq $testIPStartRange -and
                    $EndRange -eq $testIPEndRange -and
                    $SubnetMask -eq '255.255.255.128' -and
                    $Name -eq $testScopeName
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
