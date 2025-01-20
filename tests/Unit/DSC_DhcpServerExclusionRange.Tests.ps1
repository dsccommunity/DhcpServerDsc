$script:dscModuleName = 'DhcpServerDsc'
$script:dscResourceName = 'MSFT_DhcpServerExclusionRange'

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
        $scopeId = '10.1.1.0'
        $ipStartRange = '10.1.1.10'
        $ipEndRange = '10.1.1.20'
        $addressFamily = 'IPv4'
        $ensure = 'Present'

        $testParams = @{
            ScopeId       = $scopeId
            IPStartRange  = $ipStartRange
            IPEndRange    = $ipEndRange
            AddressFamily = $addressFamily
        }

        $badRangeParams = @{
            ScopeId       = $scopeId
            IPStartRange  = $ipEndRange
            IPEndRange    = $ipStartRange
            AddressFamily = $addressFamily
            Ensure        = $ensure
        }

        $getFakeDhcpExclusionRange = {
            return @(
                [PSCustomObject] @{
                    ScopeId    = $scopeId
                    StartRange = [IPAddress]$ipStartRange
                    EndRange   = [IPAddress]$ipEndRange
                }
            )
        }

        $getFakeDhcpExclusionRangeBadRange = {
            return @(
                [PSCustomObject] @{
                    ScopeId      = $scopeId
                    IPStartRange = [IPAddress]$ipEndRange
                    IPEndRange   = [IPAddress]$ipStartRange
                }
            )
        }

        Describe 'DhcpServerExclusionRange\Get-TargetResource' {
            Mock -CommandName Get-DhcpServerv4ExclusionRange -MockWith $getFakeDhcpExclusionRange
            Mock -CommandName Assert-Module

            It 'Should call "Assert-Module" to ensure "DHCPServer" module is available' {
                $result = Get-TargetResource @testParams

                Assert-MockCalled -CommandName Assert-Module
            }

            It 'Returns a "System.Collections.Hashtable" object type' {
                $result = Get-TargetResource @testParams
                $result | Should -BeOfType [System.Collections.Hashtable]
            }

            It 'Returns all correct values' {
                Mock -CommandName Get-DhcpServerv4ExclusionRange -MockWith $getFakeDhcpExclusionRange

                $result = Get-TargetResource @testParams
                $result.Ensure | Should -Be $ensure
                $result.ScopeId | Should -Be $scopeId
                $result.IPStartRange | Should -Be $ipStartRange
                $result.IPEndRange | Should -Be $ipEndRange
                $result.AddressFamily | Should -Be $addressFamily
            }

            It 'Returns the properties as $null when the exclusion does not exist' {
                Mock -CommandName Get-DhcpServerv4ExclusionRange { return $null }

                $result = Get-TargetResource @testParams
                $result.Ensure | Should -Be 'Absent'
                $result.ScopeId | Should -Be $scopeId
                $result.IPStartRange | Should -Be $null
                $result.IPEndRange | Should -Be $null
                $result.AddressFamily | Should -Be $addressFamily
            }
        }


        Describe 'DhcpServerExclusionRange\Test-TargetResource' {
            Mock -CommandName Assert-Module

            It 'Returns a "System.Boolean" object type' {
                Mock -CommandName Get-DhcpServerv4ExclusionRange -MockWith $getFakeDhcpExclusionRange

                $result = Test-TargetResource @testParams -Ensure 'Present'
                $result | Should -BeOfType [System.Boolean]
            }

            It 'Returns $true when the exclusion exists and Ensure = Present' {
                Mock -CommandName Get-DhcpServerv4ExclusionRange -MockWith $getFakeDhcpExclusionRange

                $result = Test-TargetResource @testParams -Ensure 'Present'
                $result | Should -Be $true
            }

            It 'Returns $false when the exclusion does not exist and Ensure = Present' {
                Mock -CommandName Get-DhcpServerv4ExclusionRange { return $null }

                $result = Test-TargetResource @testParams -Ensure 'Present'
                $result | Should -Be $false
            }

            It 'Returns $false when the exclusion exists and Ensure = Absent ' {
                Mock -CommandName Get-DhcpServerv4ExclusionRange -MockWith $getFakeDhcpExclusionRange

                $result = Test-TargetResource @testParams -Ensure 'Absent'
                $result | Should -Be $false
            }

            It 'Throws RangeNotCorrect exception when the start range is greater than the end range' {
                { Test-TargetResource @badRangeParams } | Should -Throw 'StartRange must be less than EndRange'
            }
        }

        Describe 'DhcpServerExclusionRange\Set-TargetResource' {
            Mock -CommandName Assert-Module
            Mock -CommandName Add-DhcpServerv4ExclusionRange
            Mock -CommandName Remove-DhcpServerv4ExclusionRange

            It 'Should call "Add-DhcpServerv4ExclusionRange" when "Ensure" = "Present" and exclusion does not exist' {
                Mock -CommandName Get-DhcpServerv4ExclusionRange { return $null }

                Set-TargetResource @testParams -Ensure 'Present'
                Assert-MockCalled -CommandName Add-DhcpServerv4ExclusionRange
            }

            It 'Should call "Remove-DhcpServerv4ExclusionRange" when "Ensure" = "Absent" and exclusion does exist' {
                Mock -CommandName Get-DhcpServerv4ExclusionRange -MockWith $getFakeDhcpExclusionRange

                Set-TargetResource @testParams -Ensure 'Absent'
                Assert-MockCalled -CommandName Remove-DhcpServerv4ExclusionRange
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
