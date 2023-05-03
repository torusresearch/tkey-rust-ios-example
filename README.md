#  Tkey ios example application document

After building complete, you can login via your google account.
If you don't have tKey, you can make your own tkey account by clicking this button, using customAuth sdk.
If you already have your account, existing account can be used as well.

Once you're logged in, you can run a number of tkey-related functions.
Buttons allow you to test various modules and tkey built-in functions.

## Main Page
![image](mainPage.png)

### how to start

Once you have the final tkey from initialize and reconstruct tkey, you can test all the features.
The first time you run `Initialize and reconstruct tkey`, two shares will be created and the threshold will be set to two.
This means that both shares will be required for login. (2/2 setting)

On the other hand, if you log in with an existing account, you would need to have the saved shares for the reconstruction to succeed.

### testing on multiple device
If you want to test logging in with the same google account on different devices, you need to set up additional settings.
Create an additional security question share by pressing the `Add password` button in the security question module.

After that, try initialize on the second device. If you try it right away, you won't have the necessary shares and fail reconstruction. 
This is because the threshold required for reconstruct is 2, but the new device only has one existing social login share.

At this point, run `Enter SecurityQuestion password` button to retrieve the security question share which was set on the old device and save it locally to the new device.
After that, when logging in from that device, you can initialize it directly without entering the security question password.


### Reset Account (Critical)

If you are unable to recover your account, such as losing your recovery key, you can reset your account.
However, you will lose your existing private key, so please use this feature with extreme caution.
