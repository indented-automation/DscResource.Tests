#Requires -Version 4.0

# Import Localized Data
Import-LocalizedData -BindingVariable localizedData

<#
.SYNOPSIS
    Validates the [Parameter()] attribute for each parameter.

.DESCRIPTION
    All parameters in a param block must contain a [Parameter()] attribute
    and it must be the first attribute for each parameter and must start with
    a capital letter P. If it also contains the mandatory attribute, then the
    mandatory attribute must be formatted correctly.

.EXAMPLE
    Measure-ParameterBlockParameterAttribute -ScriptBlockAst $ScriptBlockAst

.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]

.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

.NOTES
    None
#>
function Measure-ParameterBlockParameterAttribute
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ParameterAst]
        $ast
    )

    try
    {
        $recordType = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]
        $record = @{
            Message  = ''
            Extent   = $ast.Extent
            Rulename = $PSCmdlet.MyInvocation.InvocationName
            Severity = 'Warning'
        }

        if ($ast.Attributes.TypeName.FullName -notcontains 'parameter')
        {
            $record['Message'] = $localizedData.ParameterBlockParameterAttributeMissing

            $record -as $recordType
        }
        elseif ($ast.Attributes[0].TypeName.FullName -ne 'parameter')
        {
            $record['Message'] = $localizedData.ParameterBlockParameterAttributeWrongPlace

            $record -as $recordType
        }
        elseif ($ast.Attributes[0].TypeName.FullName -cne 'Parameter')
        {
            $record['Message'] = $localizedData.ParameterBlockParameterAttributeLowerCase

            $record -as $recordType
        }

        $mandatoryNamedArgument = $ast.Find( {
            $args[0] -is [System.Management.Automation.Language.NamedAttributeArgumentAst] -and
            $args[0].ArgumentName -eq 'Mandatory'
        }, $false)
        if ($mandatoryNamedArgument)
        {
            $invalidFormat = $false
            try {
                $value = $mandatoryNamedArgument.Argument.SafeGetValue()
                if ($value -eq $false)
                {
                    $invalidFormat = $true
                }
            }
            catch
            {
                $invalidFormat = $true
            }

            if ($mandatoryNamedArgument.ArgumentName -cne 'Mandatory')
            {
                $invalidFormat = $true
            }
            
            if ($mandatoryNamedArgument.Argument.VariablePath.UserPath -cne 'true')
            {
                $invalidFormat = $true
            }

            if ($invalidFormat)
            {
                $record['Message'] = $localizedData.ParameterBlockParameterMandatoryAttributeWrongFormat

                $record -as $recordType
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

Export-ModuleMember -Function Measure*
