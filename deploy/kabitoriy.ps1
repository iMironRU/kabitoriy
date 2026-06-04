# Кабиторий — менеджмент-скрипт развёртывания (заготовка)
param(
    [Parameter(Mandatory = $true)][ValidateSet('deploy', 'update', 'remove')]
    [string]$Command,
    [ValidateSet('extension', 'standalone')]
    [string]$Form = 'extension'
)

switch ($Command) {
    'deploy' { Write-Host "TODO: развернуть ($Form)" }
    'update' { Write-Host "TODO: обновить ($Form)" }
    'remove' { Write-Host "TODO: удалить ($Form)" }
}
