﻿#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xDhcpServer' `
    -DSCResourceName 'MSFT_DhcpServerExclusionRange' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope 'MSFT_DhcpServerExclusionRange' {
       
        $scopeId       = '10.1.1.0'
        $ipStartRange  = '10.1.1.10'
        $ipEndRange    = '10.1.1.20'
        $addressFamily = 'IPv4'
        $ensure        = 'Present'

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
                [pscustomobject]@{
                    ScopeId    = $scopeId
                    StartRange = [IPAddress]$ipStartRange
                    EndRange   = [IPAddress]$ipEndRange
                }
            )
        }

        $getFakeDhcpExclusionRangeBadRange = {
            return @(
                [pscustomobject]@{
                    ScopeId       = $scopeId
                    IPStartRange  = [IPAddress]$ipEndRange
                    IPEndRange    = [IPAddress]$ipStartRange
                }
            )
        }

        Describe 'xDhcpServer\Get-TargetResource' {

            Mock Get-DhcpServerv4ExclusionRange -MockWith $getFakeDhcpExclusionRange
            Mock Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }

            It 'Should call "Assert-Module" to ensure "DHCPServer" module is available' {
                 
                $result = Get-TargetResource @testParams

                Assert-MockCalled -CommandName Assert-Module
            }

            It 'Returns a "System.Collections.Hashtable" object type' {

                $result = Get-TargetResource @testParams
                $result | Should BeOfType [System.Collections.Hashtable]
            }

            It 'Returns all correct values'{
                
                Mock Get-DhcpServerv4ExclusionRange -MockWith $getFakeDhcpExclusionRange
            
                $result = Get-TargetResource @testParams
                $result.Ensure        | Should Be $ensure
                $result.ScopeId       | Should Be $scopeId
                $result.IPStartRange  | Should Be $ipStartRange
                $result.IPEndRange    | Should Be $ipEndRange
                $result.AddressFamily | Should Be $addressFamily
            }

            It 'Returns the properties as $null when the exclusion does not exist' {
                
                Mock Get-DhcpServerv4ExclusionRange {return $null}
            
                $result = Get-TargetResource @testParams
                $result.Ensure        | Should Be 'Absent'
                $result.ScopeId       | Should Be $scopeId
                $result.IPStartRange  | Should Be $null
                $result.IPEndRange    | Should Be $null
                $result.AddressFamily | Should Be $addressFamily
            }
        }

        
        Describe 'xDhcpServer\Test-TargetResource' {

            Mock Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }

            It 'Returns a "System.Boolean" object type' {
            
                Mock Get-DhcpServerv4ExclusionRange -MockWith $getFakeDhcpExclusionRange

                $result = Test-TargetResource @testParams -Ensure 'Present'
                $result | Should BeOfType [System.Boolean]
            }
            
            It 'Returns $true when the exclusion exists and Ensure = Present' {
                
                Mock Get-DhcpServerv4ExclusionRange -MockWith $getFakeDhcpExclusionRange
                
                $result = Test-TargetResource @testParams -Ensure 'Present'
                $result | Should Be $true
            }

            It 'Returns $false when the exclusion does not exist and Ensure = Present' {
            
                Mock Get-DhcpServerv4ExclusionRange {return $null}
                
                $result = Test-TargetResource @testParams -Ensure 'Present'
                $result | Should Be $false
            }

            It 'Returns $false when the exclusion exists and Ensure = Absent ' {

                Mock Get-DhcpServerv4ExclusionRange -MockWith $getFakeDhcpExclusionRange

                $result = Test-TargetResource @testParams -Ensure 'Absent'
                $result | Should Be $false
            }

            It 'Throws RangeNotCorrect exception when the start range is greater than the end range' {
                {Test-TargetResource @badRangeParams} | Should Throw "StartRange must be less than EndRange"
            }
        }

        Describe 'xDhcpServer\Set-TargetResource' {
        
            Mock Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }
            Mock Add-DhcpServerv4ExclusionRange
            Mock Remove-DhcpServerv4ExclusionRange

            It 'Should call "Add-DhcpServerv4ExclusionRange" when "Ensure" = "Present" and exclusion does not exist' {
                
                Mock Get-DhcpServerv4ExclusionRange {return $null}

                Set-TargetResource @testParams -Ensure 'Present'
                Assert-MockCalled -CommandName Add-DhcpServerv4ExclusionRange
            }

            It 'Should call "Remove-DhcpServerv4ExclusionRange" when "Ensure" = "Absent" and exclusion does exist' {
            
                Mock Get-DhcpServerv4ExclusionRange -MockWith $getFakeDhcpExclusionRange
                
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
