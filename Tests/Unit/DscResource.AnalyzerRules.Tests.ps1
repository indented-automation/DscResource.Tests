$script:ModuleName = (Get-Item $pscommandpath).BaseName -replace '\.Tests'
$script:moduleRootPath = Join-Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) $script:ModuleName

Describe "$($script:ModuleName) Unit Tests" {
    BeforeAll {
        $modulePath = Join-Path -Path $script:moduleRootPath -ChildPath "$($script:ModuleName).psm1"
        Import-LocalizedData -BindingVariable localizedData -BaseDirectory $script:moduleRootPath -FileName "$($script:ModuleName).psd1"
    }

    Describe 'Measure-ParameterBlockParameterAttribute' {
        Context 'ParameterBlockAttributeMissing' {
            It 'Writes a record, when ParameterAttribute is missing' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            $ParameterName
                        )
                    }
                '

                $record = Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath
                @($record).Count | Should Be 1
                $record.Message | Should Be $localizedData.ParameterBlockParameterAttributeMissing
            }

            It 'Does not write a record, when ParameterAttribute is present' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            [Parameter()]
                            $ParameterName
                        )
                    }
                '

                Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath | Should BeNullOrEmpty
            }
        }

        Context 'ParameterBlockParameterAttributeWrongPlace' {
            It 'Writes a record, when ParameterAttribute is not declared first' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            [ValidateSet("one", "two")]
                            [Parameter()]
                            $ParameterName
                        )
                    }
                '

                $record = Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath
                @($record).Count | Should Be 1
                $record.Message | Should Be $localizedData.ParameterBlockParameterAttributeWrongPlace
            }

            It 'Does not write a record, when ParameterAttribute is declared first' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            [Parameter()]
                            [ValidateSet("one", "two")]
                            $ParameterName
                        )
                    }
                '

                Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath | Should BeNullOrEmpty
            }
        }
        
        Context 'ParameterBlockParameterAttributeLowerCase' {
            It 'Writes a record, when ParameterAttribute is written in lower case' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            [parameter()]
                            $ParameterName
                        )
                    }
                '

                $record = Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath
                @($record).Count | Should Be 1
                $record.Message | Should Be $localizedData.ParameterBlockParameterAttributeLowerCase
            }

            It 'Does not write a record, when ParameterAttribute is written correctly' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            [Parameter()]
                            $ParameterName
                        )
                    }
                '

                Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath | Should BeNullOrEmpty
            }
        }

        Context 'ParameterBlockParameterMandatoryAttributeWrongFormat' {
            It 'Writes a record, when Mandatory is included and set to $false' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            [Parameter(Mandatory = $false)]
                            $ParameterName
                        )
                    }
                '

                $record = Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath
                @($record).Count | Should Be 1
                $record.Message | Should Be $localizedData.ParameterBlockParameterMandatoryAttributeWrongFormat
            }

            It 'Writes a record, when Mandatory is lower-case' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            [Parameter(mandatory = $true)]
                            $ParameterName
                        )
                    }
                '

                $record = Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath
                @($record).Count | Should Be 1
                $record.Message | Should Be $localizedData.ParameterBlockParameterMandatoryAttributeWrongFormat
            }

            It 'Writes a record, when Mandatory does not include an explicit argument' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            [Parameter(Mandatory)]
                            $ParameterName
                        )
                    }
                '

                $record = Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath
                @($record).Count | Should Be 1
                $record.Message | Should Be $localizedData.ParameterBlockParameterMandatoryAttributeWrongFormat
            }

            It 'Writes a record, when Mandatory is incorrectly written and other parameters are used' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            [Parameter(Mandatory = $false, ParameterSetName = "SetName")]
                            $ParameterName
                        )
                    }
                '

                $record = Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath
                @($record).Count | Should Be 1
                $record.Message | Should Be $localizedData.ParameterBlockParameterMandatoryAttributeWrongFormat
            }

            It 'Does not write a record, when Mandatory is correctly written' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            [Parameter(Mandatory = $true)]
                            $ParameterName
                        )
                    }
                '

                Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath | Should BeNullOrEmpty
            }

            It 'Does not write a record, when Mandatory is not present and other parameters are' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            [Parameter(HelpMessage = "HelpMessage")]
                            $ParameterName
                        )
                    }
                '

                Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath | Should BeNullOrEmpty
            }

            It 'Does not write a record, when Mandatory is correctly written and other parameters are listed' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            [Parameter(Mandatory = $true, ParameterSetName = "SetName")]
                            $ParameterName
                        )
                    }
                '

                Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath | Should BeNullOrEmpty
            }

            It 'Does not write a record, when Mandatory is correctly written and other attributes are listed' {
                $definition = '
                    function Get-TargetResource
                    {
                        Param (
                            [Parameter(Mandatory = $true)]
                            [ValidateSet("one", "two")]
                            $ParameterName
                        )
                    }
                '

                Invoke-ScriptAnalyzer -ScriptDefinition $definition -CustomRulePath $modulePath | Should BeNullOrEmpty
            }            
        }
    }
}
