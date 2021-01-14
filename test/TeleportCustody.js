const TeleportCustodyTest = artifacts.require('TeleportCustodyTest');
const TetherTokenTest = artifacts.require("TetherTokenTest");

async function tryCatch(promise, reason) {
  try {
    await promise;
  }
  catch (error) {
    const isErrorOccur = error.message.includes(reason);
    assert.equal(isErrorOccur, true, `Expected to fail with ${reason}, but failed with: ${error.message}`);
  }
};

contract('TeleportCustody (USDT) Tests', (accounts) => {
  let teleportCustody;

  const owner = accounts[0];
  const adminOne = accounts[1];
  const adminTwo = accounts[2];
  const user = accounts[3];

  beforeEach('setup contract for each test', async () => {
    teleportCustody = await TeleportCustodyTest.new(TetherTokenTest.address);
  });

  describe('TeleportAdmin', () => {
    describe('updateAdmin()', () => {
      it('should set allowedAmount of an admin', async () => {
        await teleportCustody.updateAdmin(adminOne, 100, { from: owner });
  
        const allowedAmount = await teleportCustody.allowedAmount(adminOne);
  
        assert.equal(allowedAmount, 100);
      })
  
      it('should update allowedAmount of an admin', async () => {
        await teleportCustody.updateAdmin(adminOne, 1000, { from: owner });
        await teleportCustody.updateAdmin(adminOne, 500, { from: owner });
  
        const allowedAmount = await teleportCustody.allowedAmount(adminOne);
  
        assert.equal(allowedAmount, 500);
      })

      it('can only be called by owner', async () => {
        await tryCatch(
          teleportCustody.updateAdmin(adminOne, 100, { from: adminOne }),
          'Ownable: caller is not the owner'
        )
      })

      it('can have multiple admins', async () => {
        await teleportCustody.updateAdmin(adminOne, 1000, { from: owner });
        await teleportCustody.updateAdmin(adminTwo, 500, { from: owner });
  
        const allowedAmountOne = await teleportCustody.allowedAmount(adminOne);
        const allowedAmountTwo = await teleportCustody.allowedAmount(adminTwo);

        assert.equal(allowedAmountOne, 1000);
        assert.equal(allowedAmountTwo, 500);
      })
    })

    describe('freeze() & unfreeze()', () => {
      it('should be able to freeze contract', async () => {
        await teleportCustody.freeze({ from: owner });

        const isFrozen = await teleportCustody.isFrozen();

        assert.equal(isFrozen, true);
      })

      it('should be able to unfreeze contract', async () => {
        await teleportCustody.freeze({ from: owner });
        await teleportCustody.unfreeze({ from: owner });

        const isFrozen = await teleportCustody.isFrozen();

        assert.equal(isFrozen, false);
      })

      it('can only be called by owner', async () => {
        await tryCatch(
          teleportCustody.freeze({ from: adminOne }),
          'Ownable: caller is not the owner'
        )

        await tryCatch(
          teleportCustody.unfreeze({ from: adminOne }),
          'Ownable: caller is not the owner'
        )
      })
    })

    describe('renounceOwnership()', () => {
      it('should be rejected', async () => {
        await tryCatch(
          teleportCustody.renounceOwnership({ from: owner }),
          'TeleportAdmin: ownership cannot be renounced'
        )
      })

      it('can only be called by owner', async () => {
        await tryCatch(
          teleportCustody.renounceOwnership({ from: adminOne }),
          'Ownable: caller is not the owner'
        )
      })
    })
  })

  describe('TeleportCustody', () => {
    describe('lock()', () => {
      it('can lock tokens from users', async () => {
        const { receipt: { rawLogs }, logs } = await teleportCustody.lock(100, '0x0000', { from: user });

        const transferEvents = rawLogs.filter(event => event.address === TetherTokenTest.address);

        assert.equal(transferEvents.length, 1);
        assert.equal(logs[0].event, 'Locked');
      })
    })

    describe('unlock()', () => {
      it('requires authorization from owner', async () => {
        await tryCatch(
          teleportCustody.unlock(100, user, '0x0000', { from: adminOne }),
          'TeleportAdmin: caller does not have sufficient authorization'
        );
      })

      it('requires sufficient authorization from owner', async () => {
        await teleportCustody.updateAdmin(adminOne, 500, { from: owner });

        await tryCatch(
          teleportCustody.unlock(1000, user, '0x0000', { from: adminOne }),
          'TeleportAdmin: caller does not have sufficient authorization'
        );
      })

      it('should unlock if admin has enough authorization', async () => {
        await teleportCustody.updateAdmin(adminOne, 500, { from: owner });
        const { receipt: { rawLogs }, logs } = await teleportCustody.unlock(100, user, '0x0000', { from: adminOne });

        const transferEvents = rawLogs.filter(event => event.address === TetherTokenTest.address);

        assert.equal(transferEvents.length, 1);
        assert.equal(logs[0].event, 'Unlocked');
        assert.equal(logs[1].event, 'AdminUpdated');
      })

      it('should unlock multiple times if admin has enough authorization', async () => {
        await teleportCustody.updateAdmin(adminOne, 500, { from: owner });
        await teleportCustody.unlock(100, user, '0x0000', { from: adminOne });
        const { receipt: { rawLogs }, logs } = await teleportCustody.unlock(100, user, '0x0001', { from: adminOne });

        const transferEvents = rawLogs.filter(event => event.address === TetherTokenTest.address);

        assert.equal(transferEvents.length, 1);
        assert.equal(logs[0].event, 'Unlocked');
        assert.equal(logs[1].event, 'AdminUpdated');
      })

      it('should block duplicated Flow hash', async () => {
        await teleportCustody.updateAdmin(adminOne, 500, { from: owner });
        await teleportCustody.unlock(100, user, '0x0000', { from: adminOne });

        await tryCatch(
          teleportCustody.unlock(100, user, '0x0000', { from: adminOne }),
          'TeleportCustody: same unlock hash has been executed'
        );
      })

      it('should block when admin has depleted authorization', async () => {
        await teleportCustody.updateAdmin(adminOne, 500, { from: owner });
        await teleportCustody.unlock(500, user, '0x0000', { from: adminOne });

        await tryCatch(
          teleportCustody.unlock(100, user, '0x0001', { from: adminOne }),
          'TeleportAdmin: caller does not have sufficient authorization'
        );
      })

      it('should block when teleport service is frozen', async () => {
        await teleportCustody.updateAdmin(adminOne, 500, { from: owner });
        await teleportCustody.freeze({ from: owner }),

        await tryCatch(
          teleportCustody.unlock(100, user, '0x0000', { from: adminOne }),
          'TeleportAdmin: contract is frozen by owner'
        );
      })

      it('should unlock when teleport service is unfrozen', async () => {
        await teleportCustody.updateAdmin(adminOne, 500, { from: owner });
        await teleportCustody.freeze({ from: owner }),

        await tryCatch(
          teleportCustody.unlock(100, user, '0x0000', { from: adminOne }),
          'TeleportAdmin: contract is frozen by owner'
        );

        await teleportCustody.unfreeze({ from: owner });

        const { receipt: { rawLogs }, logs } = await teleportCustody.unlock(100, user, '0x0000', { from: adminOne });

        const transferEvents = rawLogs.filter(event => event.address === TetherTokenTest.address);

        assert.equal(transferEvents.length, 1);
        assert.equal(logs[0].event, 'Unlocked');
        assert.equal(logs[1].event, 'AdminUpdated');
      })
    })

    describe('unlockByOwner()', () => {
      it('should unlock', async () => {
        const { receipt: { rawLogs }, logs } = await teleportCustody.unlockByOwner(100, user, '0x0000', { from: owner });

        const transferEvents = rawLogs.filter(event => event.address === TetherTokenTest.address);

        assert.equal(transferEvents.length, 1);
        assert.equal(logs[0].event, 'Unlocked');
      })

      it('should unlock multiple times', async () => {
        await teleportCustody.unlockByOwner(100, user, '0x0000', { from: owner });
        const { receipt: { rawLogs }, logs } = await teleportCustody.unlockByOwner(100, user, '0x0001', { from: owner });

        const transferEvents = rawLogs.filter(event => event.address === TetherTokenTest.address);

        assert.equal(transferEvents.length, 1);
        assert.equal(logs[0].event, 'Unlocked');
      })

      it('should block duplicated Flow hash', async () => {
        await teleportCustody.unlockByOwner(100, user, '0x0000', { from: owner });

        await tryCatch(
          teleportCustody.unlockByOwner(100, user, '0x0000', { from: owner }),
          'TeleportCustody: same unlock hash has been executed'
        );
      })

      it('should block duplicated Flow hash by admin', async () => {
        await teleportCustody.updateAdmin(adminOne, 500, { from: owner });
        await teleportCustody.unlock(100, user, '0x0000', { from: adminOne });

        await tryCatch(
          teleportCustody.unlockByOwner(100, user, '0x0000', { from: owner }),
          'TeleportCustody: same unlock hash has been executed'
        );
      })

      it('should block when teleport service is frozen', async () => {
        await teleportCustody.freeze({ from: owner }),

        await tryCatch(
          teleportCustody.unlockByOwner(100, user, '0x0000', { from: owner }),
          'TeleportAdmin: contract is frozen by owner'
        );
      })

      it('should unlock when teleport service is unfrozen', async () => {
        await teleportCustody.freeze({ from: owner }),

        await tryCatch(
          teleportCustody.unlockByOwner(100, user, '0x0000', { from: owner }),
          'TeleportAdmin: contract is frozen by owner'
        );

        await teleportCustody.unfreeze({ from: owner });

        const { receipt: { rawLogs }, logs } = await teleportCustody.unlockByOwner(100, user, '0x0000', { from: owner });

        const transferEvents = rawLogs.filter(event => event.address === TetherTokenTest.address);

        assert.equal(transferEvents.length, 1);
        assert.equal(logs[0].event, 'Unlocked');
      })

      it('can only be called by the owner', async () => {
        await tryCatch(
          teleportCustody.unlockByOwner(100, user, '0x0000', { from: adminOne }),
          'Ownable: caller is not the owner'
        );
      })
    })
  })
});
