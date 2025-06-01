@{
    PSDependOptions                = @{
        AddToPath  = $true
        Target     = 'output\RequiredModules'
        Parameters = @{
            Repository = 'PSGallery'
        }
    }

    InvokeBuild                    = 'latest'
    PSScriptAnalyzer               = 'latest'
    Pester                         = 'latest'
    Plaster                        = 'latest'
    ModuleBuilder                  = 'latest'
    ChangelogManagement            = 'latest'
    Sampler                        = 'latest'
    'Sampler.GitHubTasks'          = 'latest'
    MarkdownLinkCheck              = 'latest'
    'DscResource.Test'             = 'latest'
    xDscResourceDesigner           = 'latest'

    <#
        Prerequisites modules needed for examples and integration tests of
        the DhcpServerDsc module.
    #>
    PSDscResources                 = '2.12.0.0'

    # Build dependent modules
    'DscResource.Common'           = 'latest'
    'DscResource.Base'             = 'latest'

    # Analyzer rules
    'DscResource.AnalyzerRules'    = 'latest'
    'Indented.ScriptAnalyzerRules' = 'latest'

    # Prerequisite modules for documentation.
    'DscResource.DocGenerator'     = @{
        Version    = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }
    PlatyPS                        = 'latest'
}
