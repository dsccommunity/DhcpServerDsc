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

Describe 'DSC_xDhcpServerReservation\Get-TargetResource' -Tag 'Get' {
    Context 'When the resource is present' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'ScopeID'
            } -MockWith {
                return [System.Net.IPAddress] '192.168.1.0'
            }

            Mock -CommandName Get-DhcpServerv4Scope
            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'IPAddress'
            } -MockWith {
                return [System.Net.IPAddress] '192.168.1.30'
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

                $testParams = @{
                    ScopeID          = '192.168.1.0'
                    ClientMACAddress = '00-15-5D-01-05-1B'
                    IPAddress        = '192.168.1.30'
                    AddressFamily    = 'IPv4'
                }

                $result = Get-TargetResource @testParams

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.ScopeID | Should -Be $testParams.ScopeID
                $result.IPAddress | Should -Be $testParams.IPAddress
                $result.ClientMACAddress | Should -Be $testParams.ClientMACAddress
                $result.Name | Should -Be (Get-ComputerName)
                $result.AddressFamily | Should -Be $testParams.AddressFamily
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
                return [System.Net.IPAddress] '192.168.1.0'
            }

            Mock -CommandName Get-DhcpServerv4Scope
            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'IPAddress'
            } -MockWith {
                return [System.Net.IPAddress] '192.168.1.30'
            }

            Mock -CommandName Get-DhcpServerv4Reservation
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeID          = '192.168.1.0'
                    ClientMACAddress = '00-15-5D-01-05-1B'
                    IPAddress        = '192.168.1.30'
                    AddressFamily    = 'IPv4'
                }

                $result = Get-TargetResource @testParams

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.ScopeID | Should -Be $testParams.ScopeID
                $result.IPAddress | Should -Be $testParams.IPAddress
                $result.ClientMACAddress | Should -BeNullOrEmpty
                $result.Name | Should -BeNullOrEmpty
                $result.AddressFamily | Should -Be $testParams.AddressFamily
                $result.Ensure | Should -Be 'Absent'
            }
        }
    }

    Context 'When the ScopeID is not valid' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'ScopeID'
            } -MockWith {
                return [System.Net.IPAddress] '192.168.1.0'
            }

            InModuleScope -ScriptBlock {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    Set-Variable -Name $PesterBoundParameters.ErrorVariable -Scope 3 -Value 'oh no'
                }
            }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeID          = '192.168.1.0'
                    ClientMACAddress = '00-15-5D-01-05-1B'
                    IPAddress        = '192.168.1.30'
                    AddressFamily    = 'IPv4'
                }

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.InvalidScopeIdMessage -f $testParams.ScopeID)

                { Get-TargetResource @testParams } | Should -Throw -ExpectedMessage $errorRecord
            }
        }
    }
}

Describe 'DSC_xDhcpServerReservation\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Update-ResourceProperties
    }

    Context 'When supplying parameters that are removed' {
        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeID          = '192.168.1.0'
                    ClientMACAddress = '00-15-5D-01-05-1B'
                    IPAddress        = '192.168.1.10'
                    AddressFamily    = 'IPv4'
                    Debug            = $true
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Update-ResourceProperties -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_xDhcpServerReservation\Test-TargetResource' -Tag 'Test' {
    Context 'When the resource is in the desired state' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'ScopeID'
            } -MockWith {
                return [System.Net.IPAddress] '192.168.1.0'
            }

            Mock -CommandName Get-DhcpServerv4Scope
            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'IPAddress'
            } -MockWith {
                return [System.Net.IPAddress] '192.168.1.30'
            }

            Mock -CommandName Update-ResourceProperties -MockWith {
                return $true
            }
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeID          = '192.168.1.0'
                    ClientMACAddress = '00-15-5D-01-05-1B'
                    IPAddress        = '192.168.1.30'
                    AddressFamily    = 'IPv4'
                    Ensure           = 'Present'
                    Debug            = $true
                }

                Test-TargetResource @testParams
            }

            Should -Invoke -CommandName Assert-Module -Exactly -Times 1 -Scope It
            Should -Invoke Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'ScopeID'
            } -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DhcpServerv4Scope -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'IPAddress'
            } -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Update-ResourceProperties -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the ScopeID is not valid' {
        BeforeAll {
            Mock -CommandName Assert-Module
            Mock -CommandName Get-ValidIPAddress -ParameterFilter {
                $ParameterName -eq 'ScopeID'
            } -MockWith {
                return [System.Net.IPAddress] '192.168.1.0'
            }

            InModuleScope -ScriptBlock {
                Mock -CommandName Get-DhcpServerv4Scope -MockWith {
                    Set-Variable -Name $PesterBoundParameters.ErrorVariable -Scope 3 -Value 'oh no'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ScopeID          = '192.168.1.0'
                    ClientMACAddress = '00-15-5D-01-05-1B'
                    IPAddress        = '192.168.1.30'
                    AddressFamily    = 'IPv4'
                }

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.InvalidScopeIdMessage -f $testParams.ScopeID)

                { Test-TargetResource @testParams } | Should -Throw -ExpectedMessage $errorRecord
            }
        }
    }
}

Describe 'DSC_xDhcpServerReservation\Update-ResourceProperties' -Tag 'Helper' {
    Context 'When a reservation exists' {
        BeforeAll {
            Mock -CommandName Get-DhcpServerv4Reservation -MockWith {
                return @{
                    ClientId  = '00-15-5D-01-05-1B'
                    Name      = Get-ComputerName
                    IPAddress = '192.168.30.10'
                }
            }
        }

        Context 'When the parameter ''Apply'' is $false' {
            Context 'When the resource is in the desired state' {
                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            ScopeID          = '192.168.30.0'
                            ClientMACAddress = '00155D01051B'
                            IPAddress        = '192.168.30.10'
                            Name             = Get-ComputerName
                            AddressFamily    = 'IPv4'
                            Ensure           = 'Present'
                        }

                        Update-ResourceProperties @testParams | Should -BeTrue
                    }

                    Should -Invoke -CommandName Get-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the resource is not in the desired state' {
                BeforeDiscovery {
                    $testCases = @(
                        @{
                            Parameter = 'ClientMACAddress'
                            Value     = '55155D01051B'
                        }
                        @{
                            Parameter = 'Name'
                            Value     = 'AnotherName'
                        }
                    )
                }

                Context 'When the ''<Parameter>'' is different' -ForEach $testCases {
                    It 'Should return the correct result' {
                        InModuleScope -Parameters $_ -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $testParams = @{
                                ScopeID          = '192.168.30.0'
                                ClientMACAddress = '00155D01051B'
                                IPAddress        = '192.168.30.10'
                                Name             = Get-ComputerName
                                AddressFamily    = 'IPv4'
                                Ensure           = 'Present'
                            }

                            $testParams.$Parameter = $Value

                            Update-ResourceProperties @testParams | Should -BeFalse
                        }

                        Should -Invoke -CommandName Get-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the resource should be absent' {
                    It 'Should return the correct result' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $testParams = @{
                                ScopeID          = '192.168.30.0'
                                ClientMACAddress = '00155D01051B'
                                IPAddress        = '192.168.30.10'
                                Name             = Get-ComputerName
                                AddressFamily    = 'IPv4'
                                Ensure           = 'Absent'
                            }

                            Update-ResourceProperties @testParams | Should -BeFalse
                        }

                        Should -Invoke -CommandName Get-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Context 'When the parameter ''Apply'' is $true' {
            Context 'When the resource is in the desired state' {
                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            ScopeID          = '192.168.30.0'
                            ClientMACAddress = '00155D01051B'
                            IPAddress        = '192.168.30.10'
                            Name             = Get-ComputerName
                            AddressFamily    = 'IPv4'
                            Ensure           = 'Present'
                            Apply            = $true
                        }

                        Update-ResourceProperties @testParams
                    }

                    Should -Invoke -CommandName Get-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the resource is not in the desired state' {
                BeforeDiscovery {
                    $testCases = @(
                        @{
                            Parameter = 'ClientMACAddress'
                            Value     = '55155D01051B'
                        }
                        @{
                            Parameter = 'Name'
                            Value     = 'AnotherName'
                        }
                    )
                }

                Context 'When the ''<Parameter>'' is different' -ForEach $testCases {
                    BeforeAll {
                        Mock -CommandName Set-DhcpServerv4Reservation
                        Mock -CommandName Write-PropertyMessage
                    }

                    It 'Should return the correct result' {
                        InModuleScope -Parameters $_ -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $testParams = @{
                                ScopeID          = '192.168.30.0'
                                ClientMACAddress = '00155D01051B'
                                IPAddress        = '192.168.30.10'
                                Name             = Get-ComputerName
                                AddressFamily    = 'IPv4'
                                Ensure           = 'Present'
                                Apply            = $true
                            }

                            $testParams.$Parameter = $Value

                            Update-ResourceProperties @testParams
                        }

                        Should -Invoke -CommandName Get-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Set-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Write-PropertyMessage -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the resource should be removed' {
                    BeforeAll {
                        Mock -CommandName Remove-DhcpServerv4Reservation
                    }

                    It 'Should call the correct mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $testParams = @{
                                ScopeID          = '192.168.30.0'
                                ClientMACAddress = '00155D01051B'
                                IPAddress        = '192.168.30.10'
                                Name             = Get-ComputerName
                                AddressFamily    = 'IPv4'
                                Ensure           = 'Absent'
                                Apply            = $true
                            }

                            Update-ResourceProperties @testParams
                        }

                        Should -Invoke -CommandName Get-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Remove-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                    }
                }
            }
        }
    }

    Context 'When a reservation does not exist' {
        BeforeAll {
            Mock -CommandName Get-DhcpServerv4Reservation
        }

        Context 'When ''Apply'' is $false' {
            Context 'When a reservation should exist' {
                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            ScopeID          = '192.168.30.0'
                            ClientMACAddress = '00155D01051B'
                            IPAddress        = '192.168.30.10'
                            Name             = Get-ComputerName
                            AddressFamily    = 'IPv4'
                            Ensure           = 'Present'
                        }

                        Update-ResourceProperties @testParams | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                }
            }

            Context 'When a reservation should not exist' {
                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            ScopeID          = '192.168.30.0'
                            ClientMACAddress = '00155D01051B'
                            IPAddress        = '192.168.30.10'
                            Name             = Get-ComputerName
                            AddressFamily    = 'IPv4'
                            Ensure           = 'Absent'
                        }

                        Update-ResourceProperties @testParams | Should -BeTrue
                    }

                    Should -Invoke -CommandName Get-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When ''Apply'' is $true' {
            Context 'When a reservation should exist' {
                Context 'When the reservation is successfully created' {
                    BeforeAll {
                        Mock -CommandName Add-DhcpServerv4Reservation
                    }

                    It 'Should call the correct mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $testParams = @{
                                ScopeID          = '192.168.30.0'
                                ClientMACAddress = '00155D01051B'
                                IPAddress        = '192.168.30.10'
                                Name             = Get-ComputerName
                                AddressFamily    = 'IPv4'
                                Ensure           = 'Present'
                                Apply            = $true
                            }

                            Update-ResourceProperties @testParams
                        }

                        Should -Invoke -CommandName Get-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Add-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the reservation fails to be created' {
                    BeforeAll {
                        Mock -CommandName Add-DhcpServerv4Reservation -MockWith { throw }
                    }

                    It 'Should throw and exception' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $testParams = @{
                                ScopeID          = '192.168.30.0'
                                ClientMACAddress = '00155D01051B'
                                IPAddress        = '192.168.30.10'
                                Name             = Get-ComputerName
                                AddressFamily    = 'IPv4'
                                Ensure           = 'Present'
                                Apply            = $true
                            }

                            { Update-ResourceProperties @testParams } | Should -Throw
                        }

                        Should -Invoke -CommandName Get-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Add-DhcpServerv4Reservation -Exactly -Times 1 -Scope It
                    }
                }
            }
        }
    }
}
