using Xunit;

namespace RetakesPlugin.Tests;

public class CommandRegistrationGateTests
{
    [Fact]
    public void TryRegister_AllowsOnlyOneRegistrationPerPluginInstance()
    {
        var gate = new CommandRegistrationGate();

        Assert.True(gate.TryRegister());
        Assert.False(gate.TryRegister());
    }
}
