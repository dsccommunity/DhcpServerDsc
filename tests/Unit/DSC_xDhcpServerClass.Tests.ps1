$script:dscModuleName = 'DhcpServerDsc'
$script:dscResourceName = 'DSC_xDhcpServerClass'

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
        $testClassName = 'Test Class'
        $testClassType = 'Vendor'
        $testAsciiData = 'test data'
        $testClassDescription = 'test class description'
        $testClassAddressFamily = 'IPv4'

        $testParams = @{
            Name          = $testClassName
            Type          = $testClassType
            AsciiData     = $testAsciiData
            AddressFamily = 'IPv4'
            Description   = $testClassDescription
            Verbose       = $true
        }

        $fakeDhcpServerClass = [PSCustomObject] @{
            Name          = $testClassName
            Type          = $testClassType
            AsciiData     = $testAsciiData
            Description   = $testClassDescription
            AddressFamily = $testClassAddressFamily
        }

        Describe 'DSC_xDhcpServerClass\Get-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module
            }

            It 'Calls "Assert-Module" to ensure "DHCPServer" module is available' {
                Mock -CommandName Get-DhcpServerv4Class -MockWith {
                    return $fakeDhcpServerClass
                }

                $result = Get-TargetResource @testParams -Ensure Present

                Assert-MockCalled -CommandName Assert-Module -ParameterFilter {
                    $ModuleName -eq 'DHCPServer'
                } -Exactly -Times 1 -Scope It
            }

            It 'Returns a "System.Collections.Hashtable" object type' {
                Mock -CommandName Get-DhcpServerv4Class -MockWith {
                    return $fakeDhcpServerClass
                }

                $result = Get-TargetResource @testParams -Ensure Present

                $result -is [System.Collections.Hashtable] | Should -Be $true
            }
        }

        Describe 'DSC_xDhcpServerClass\Test-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module
            }

            It 'Returns a "System.Boolean" object type' {
                Mock -CommandName Get-DhcpServerv4Class -MockWith {
                    return $fakeDhcpServerClass
                }

                $result = Test-TargetResource @testParams -Ensure Present

                $result -is [System.Boolean] | Should -Be $true
            }

            It 'Passes when all parameters are correct' {
                Mock -CommandName Get-DhcpServerv4Class {
                    return $fakeDhcpServerClass
                }

                $result = Test-TargetResource @testParams -Ensure Present

                $result | Should -Be $true
            }

        }

        Describe 'DSC_xDhcpServerClass\Set-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-Module
            }

            It 'Calls "Add-DhcpServerv4Class" when "Ensure" = "Present" and class does not exist' {
                Mock -CommandName Get-DhcpServerv4Class -MockWith {
                    return $null
                }

                Mock -CommandName Set-DhcpServerv4Class
                Mock -CommandName Add-DhcpServerv4Class

                Set-TargetResource @testParams -Ensure Present

                Assert-MockCalled -CommandName Add-DhcpServerv4Class -Exactly -Times 1 -Scope It
            }

            It 'Calls "Remove-DhcpServerv4Class" when "Ensure" = "Absent" and scope does exist' {
                Mock -CommandName Get-DhcpServerv4Class -MockWith {
                    return $fakeDhcpServerClass
                }

                Mock -CommandName Remove-DhcpServerv4Class

                Set-TargetResource @testParams -Ensure 'Absent'

                Assert-MockCalled -CommandName Remove-DhcpServerv4Class -Exactly -Times 1 -Scope It
            }

            It 'Calls Set-DhcpServerv4Class when asciidata changes' {
                Mock -CommandName Get-DhcpServerv4Class -MockWith {
                    return $fakeDhcpServerClass
                }

                Mock -CommandName Set-DhcpServerv4Class

                $testParams.AsciiData = 'differentdata'

                Set-TargetResource @testParams -Ensure 'Present'

                Assert-MockCalled -CommandName Set-DhcpServerv4Class -Exactly -Times 1 -Scope It
            }
        }
    } #end InModuleScope
}
finally
{
    Invoke-TestCleanup
}
