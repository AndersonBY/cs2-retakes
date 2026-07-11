namespace RetakesPlugin;

public sealed class CommandRegistrationGate
{
    private bool _registered;

    public bool TryRegister()
    {
        if (_registered)
            return false;

        _registered = true;
        return true;
    }
}
