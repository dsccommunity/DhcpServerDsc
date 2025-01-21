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
    $script:dscResourceName = 'DSC_xDhcpServerReservation'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '.\Stubs\DhcpServer_2016_OSBuild_14393_2395.psm1')

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

Describe 'DSC_xDhcpServerReservation\Get-TargetResource' -Tag 'Get' {
    Context 'When the resource is present' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'ScopeID'
            } -MockWith {
                return [System.Net.IPAddress]::Parse('192.168.1.0')
            }

            Mock -CommandName Get-DhcpServerv4Scope
            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'IPAddress'
            } -MockWith {
                return [System.Net.IPAddress]::Parse('192.168.1.30')
            }

            Mock -CommandName Get-DhcpServerv4Reservation -MockWith {
                return @{
                    ClientId  = '00-15-5D-01-05-1B'
                    Name      = Get-ComputerName
                    IPAddress = '192.168.1.30'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParams = @{
                    ScopeID          = '192.168.1.0'
                    ClientMACAddress = '00-15-5D-01-05-1B'
                    IPAddress        = '192.168.1.30'
                    AddressFamily    = 'IPv4'
                }

                $result = Get-TargetResource @mockParams

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.ScopeID | Should -Be $mockParams.ScopeID
                $result.IPAddress | Should -Be $mockParams.IPAddress
                $result.ClientMACAddress | Should -Be $mockParams.ClientMACAddress
                $result.Name | Should -Be (Get-ComputerName)
                $result.AddressFamily | Should -Be $mockParams.AddressFamily
                $result.Ensure | Should -Be 'Present'
            }
        }
    }

    Context 'When the resource is absent' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'ScopeID'
            } -MockWith {
                return [System.Net.IPAddress]::Parse('192.168.1.0')
            }

            Mock -CommandName Get-DhcpServerv4Scope
            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'IPAddress'
            } -MockWith {
                return [System.Net.IPAddress]::Parse('192.168.1.30')
            }

            Mock -CommandName Get-DhcpServerv4Reservation
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParams = @{
                    ScopeID          = '192.168.1.0'
                    ClientMACAddress = '00-15-5D-01-05-1B'
                    IPAddress        = '192.168.1.30'
                    AddressFamily    = 'IPv4'
                }

                $result = Get-TargetResource @mockParams

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.ScopeID | Should -Be $mockParams.ScopeID
                $result.IPAddress | Should -Be $mockParams.IPAddress
                $result.ClientMACAddress | Should -BeNullOrEmpty
                $result.Name | Should -BeNullOrEmpty
                $result.AddressFamily | Should -Be $mockParams.AddressFamily
                $result.Ensure | Should -Be 'Absent'
            }
        }
    }

    # Context 'When the ScopeID is not valid' {
    #     BeforeAll {
    #         Mock -CommandName Assert-Module
    #         Mock -CommandName Get-ValidIPAddress -ParameterFilter {
    #             $ParameterName -eq 'ScopeID'
    #         } -MockWith {
    #             return [System.Net.IPAddress]::Parse('192.168.1.0')
    #         }

    #         Mock -CommandName Get-DhcpServerv4Scope -MockWith { Write-Error -Message 'Missing' }
    #     }

    #     It 'Should return the correct result' {
    #         InModuleScope -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             $mockParams = @{
    #                 ScopeID          = '192.168.1.0'
    #                 ClientMACAddress = '00-15-5D-01-05-1B'
    #                 IPAddress        = '192.168.1.30'
    #                 AddressFamily    = 'IPv4'
    #             }

    #             $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.InvalidScopeIdMessage -f $mockParams.ScopeID)

    #             { Get-TargetResource @mockParams } | Should -Throw -ExpectedMessage $errorRecord

    #         }
    #     }
    # }
}
