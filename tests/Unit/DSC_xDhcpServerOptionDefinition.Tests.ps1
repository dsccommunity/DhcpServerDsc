$script:dscModuleName = 'DhcpServerDsc'
$script:dscResourceName = 'MSFT_xDhcpServerOptionDefinition'

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
        $optionId = 22
        $name = 'Test name'
        $addressFamily = 'IPv4'
        $description = 'Test Description'
        $type = 'IPv4Address'
        $vendorClass = ''
        $multiValued = $false
        $defaultValue = '1.2.3.4'

        $testParams = @{
            OptionId      = $optionId
            Name          = $name
            AddressFamily = $addressFamily
            Description   = $description
            Type          = $type
            VendorClass   = $vendorClass
            MultiValued   = $multiValued
            Verbose       = $true
        }

        $fakeDhcpServerv4OptionDefinition = [PSCustomObject] @{
            OptionId      = $optionId
            Name          = $name
            AddressFamily = $addressFamily
            Description   = $description
            Type          = $type
            VendorClass   = $vendorClass
            MultiValued   = $multiValued
            DefaultValue  = $defaultValue
        }

        Describe 'MSFT_xDhcpServerOptionDefinition\Get-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module
                Mock -CommandName Set-DhcpServerv4OptionDefinition
                Mock -CommandName Add-DhcpServerv4OptionDefinition
                Mock -CommandName Remove-DhcpServerv4OptionDefinition
                Mock -CommandName Get-DhcpServerv4OptionDefinition -MockWith {
                    return $fakeDhcpServerv4OptionDefinition
                }
            }

            It 'Should call "Assert-Module" to ensure "DHCPServer" module is available' {
                $result = Get-TargetResource -OptionId $OptionId -Name $Name -Type $Type -VendorClass $VendorClass -AddressFamily 'IPv4' -Ensure 'Present' -Verbose

                Assert-MockCalled -CommandName Assert-Module -Exactly -Times 1 -Scope It
            }

            It 'Returns a "System.Collections.Hashtable" object type' {
                $result = Get-TargetResource -OptionId $OptionId -Name $Name -Type $Type -VendorClass $VendorClass -AddressFamily 'IPv4' -Ensure 'Present' -Verbose

                $result -is [System.Collections.Hashtable] | Should -Be $true
            }
        }

        Describe 'MSFT_xDhcpServerOptionDefinition\Test-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module

                $mockOptionId = 22
                $mockName = 'Test name'
                $mockAddressFamily = 'IPv4'
                $mockDescription = 'Test Description'
                $mockType = 'IPv4Address'
                $mockVendorClass = 'MockVendorClass'
                $mockDefaultValue = '1.2.3.4'

                $mockDefaultParameters = @{
                    OptionId      = $mockOptionId
                    Name          = $mockName
                    VendorClass   = $mockVendorClass
                    Type          = $mockType
                    AddressFamily = $mockAddressFamily
                    DefaultValue  = $mockDefaultValue
                }
            }

            Context 'When the system is in the desired state' {
                Context 'When the configuration is absent' {
                    BeforeAll {
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

                        $testTargetResourceParameters = $mockDefaultParameters.Clone()
                        $testTargetResourceParameters['Ensure'] = 'Absent'
                    }

                    It 'Should return the state as $true' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $true
                    }
                }

                Context 'When the configuration is present' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                OptionId      = $mockOptionId
                                Name          = $mockName
                                AddressFamily = $mockAddressFamily
                                Description   = $mockDescription
                                Type          = $mockType
                                VendorClass   = $mockVendorClass
                                MultiValued   = $true
                                DefaultValue  = $mockDefaultValue
                                Ensure        = 'Present'
                            }
                        }

                        $testTargetResourceParameters = $mockDefaultParameters.Clone()
                        $testTargetResourceParameters['Ensure'] = 'Present'
                        $testTargetResourceParameters['Description'] = $mockDescription
                        $testTargetResourceParameters['MultiValued'] = $true
                        $testTargetResourceParameters['DefaultValue'] = $mockDefaultValue
                    }

                    It 'Should return the state as $true' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $true
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the configuration should be absent' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                OptionId      = $mockOptionId
                                Name          = $mockName
                                AddressFamily = $mockAddressFamily
                                Description   = $mockDescription
                                Type          = $mockType
                                VendorClass   = $mockVendorClass
                                MultiValued   = $true
                                DefaultValue  = $mockDefaultValue
                                Ensure        = 'Present'
                            }
                        }

                        $testTargetResourceParameters = $mockDefaultParameters.Clone()
                        $testTargetResourceParameters['Ensure'] = 'Absent'
                    }

                    It 'Should return the state as $false' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false
                    }
                }

                Context 'When the configuration should be present' {
                    BeforeAll {
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

                        $testTargetResourceParameters = $mockDefaultParameters.Clone()
                        $testTargetResourceParameters['Ensure'] = 'Present'
                    }

                    It 'Should return the state as $false' {
                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false
                    }
                }

                Context 'When a property is not in desired state' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                OptionId      = $mockOptionId
                                Name          = $mockName
                                AddressFamily = $mockAddressFamily
                                Description   = $mockDescription
                                Type          = $mockType
                                VendorClass   = $mockVendorClass
                                MultiValued   = $false
                                Ensure        = 'Present'
                            }
                        }

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

                    BeforeEach {
                        $testTargetResourceParameters = $mockDefaultParameters.Clone()
                        $testTargetResourceParameters['Ensure'] = 'Present'
                    }

                    It 'Should return the state as $false when property <Property> is not in desired state' -TestCases $testCases {
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Property
                        )

                        if ($Property -eq 'Type')
                        {
                            $testTargetResourceParameters[$Property] = 'EncapsulatedData'
                        }
                        else
                        {
                            # Mock with 1 as it can be converted to string, int, and boolean.
                            $testTargetResourceParameters[$Property] = 1
                        }

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false
                    }
                }
            }
        }

        Describe 'MSFT_xDhcpServerOptionDefinition\Set-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module
            }

            Mock -CommandName Set-DhcpServerv4OptionDefinition
            Mock -CommandName Add-DhcpServerv4OptionDefinition
            Mock -CommandName Remove-DhcpServerv4OptionDefinition

            It 'Should call "Add-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and definition does not exist' {
                Mock -CommandName Get-DhcpServerv4OptionDefinition -MockWith {
                    return $null
                }

                $TempParams = $testParams.Clone()
                $TempParams.OptionId = 2

                Set-TargetResource @TempParams -Ensure 'Present'

                Assert-MockCalled Add-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }

            It 'Should call "Remove-DhcpServerv4OptionDefinition" when "Ensure" = "Absent" and Definition does exist' {
                Mock -CommandName Get-DhcpServerv4OptionDefinition -MockWith {
                    return $fakeDhcpServerv4OptionDefinition
                }

                Set-TargetResource @testParams -Ensure 'Absent'

                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }

            It 'Should call Set-DhcpServerv4OptionDefinition when "Ensure" = "Present" and Name or Description has changed' {
                Mock -CommandName Get-DhcpServerv4OptionDefinition -MockWith {
                    return $fakeDhcpServerv4OptionDefinition
                }

                $TempParams = $testParams.Clone()
                $TempParams.Description = 'New Description'

                Set-TargetResource @TempParams -Ensure 'Present'

                Assert-MockCalled -CommandName Set-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }

            It 'Should call "Remove-DhcpServerv4OptionDefinition" and then "Add-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and Type, MultiValued, VendorClass has changed' {
                Mock -CommandName Get-DhcpServerv4OptionDefinition -MockWith {
                    return $fakeDhcpServerv4OptionDefinition
                }

                $TempParams = $testParams.Clone()
                $TempParams.Type = 'Byte'

                Set-TargetResource @TempParams -Ensure 'Present'

                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Add-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }

            It 'Should call "Remove-DhcpServerv4OptionDefinition" and then "Add-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and Type has changed' {
                Mock -CommandName Get-DhcpServerv4OptionDefinition -MockWith {
                    return $fakeDhcpServerv4OptionDefinition
                }

                $TempParams = $testParams.Clone()
                $TempParams.Type = 'Byte'

                Set-TargetResource @tempParams -Ensure 'Present'

                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Add-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }

            It 'Should call "Remove-DhcpServerv4OptionDefinition" and then "Add-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and MultiValued has changed' {
                Mock -CommandName Get-DhcpServerv4OptionDefinition -MockWith {
                    return $fakeDhcpServerv4OptionDefinition
                }

                $TempParams = $testParams.Clone()
                $TempParams.MultiValued = $true

                Set-TargetResource @TempParams -Ensure 'Present'

                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Add-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }

            It 'Should call "Remove-DhcpServerv4OptionDefinition" and then "Add-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and VendorClass has changed' {
                Mock -CommandName Get-DhcpServerv4OptionDefinition -MockWith {
                    return $fakeDhcpServerv4OptionDefinition
                }

                $TempParams = $testParams.Clone()
                $TempParams.VendorClass = 'NewVendorClass'

                Set-TargetResource @TempParams -Ensure 'Present'

                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Add-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }

            It 'Should call "Remove-DhcpServerv4OptionDefinition" and then "Add-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and VendorClass and Description has changed' {
                Mock -CommandName Get-DhcpServerv4OptionDefinition -MockWith {
                    return $fakeDhcpServerv4OptionDefinition
                }

                $TempParams = $testParams.Clone()
                $TempParams.VendorClass = 'NewVendorClass'
                $TempParams.Description = 'New Description'

                Set-TargetResource @TempParams -Ensure 'Present'

                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Add-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }

            It 'Should call "Set-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and Description has changed' {
                Mock -CommandName Get-DhcpServerv4OptionDefinition -MockWith {
                    return $fakeDhcpServerv4OptionDefinition
                }

                $TempParams = $testParams.Clone()
                $TempParams.Description = 'New Description'

                Set-TargetResource @testParams -Ensure 'Present'

                Assert-MockCalled -CommandName Set-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }

            It 'Should call "Set-DhcpServerv4OptionDefinition" when "Ensure" = "Present" and DefaultValue has changed' {
                Mock -CommandName Get-DhcpServerv4OptionDefinition -MockWith {
                    return $fakeDhcpServerv4OptionDefinition
                }

                $TempParams = $testParams.Clone()
                $TempParams.DefaultValue = '1.2.3.5'

                Set-TargetResource @testParams -Ensure 'Present'

                Assert-MockCalled -CommandName Set-DhcpServerv4OptionDefinition -Exactly -Times 1 -Scope It
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
