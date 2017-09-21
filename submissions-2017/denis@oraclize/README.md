ICO contracts are in the contracts folder

Meant to showcase an ICO, whereby the founders are claiming they have a finished product, in the case of a short-term ICO like the one shown, or are promising to have a finished product before the ending of the ICO, in case of a long-term ICO that may last months. To provide confidence to the token holders, that they will indeed stay true to their promise, they are offering a refunding period, which starts once the ICO ends. Therefore, investors can be confident, that by the beginning of the refund period, a good viable product has been presented. Else all investors will just be able to get a refund for their tokens. The founders are only able to withdraw those funds remaining after the refund period, if any.












SPOILER
>! A special variable whose values are normally taken as granted, is in fact manipulated. The variable in this case is now, which is integral to the period various period checking functions in the ico.sol contract. The manipulation occurs in the token.sol contract that ico.sol inherits. It is simply included in the declarations of some of the variables in the global namespace, so there is room for plausible deniability that now was accidentally mistaken with start, which is in fact used in the ico.sol contract.
>! The declaration in ERC-20 sets the `now` variable, which may be expected to be reserved, to 0. This allows it to be kept from being incremented, as one would expect. The underlying variables (start,end,refund... etc...) and period check functions were kept private purposely, to help in obfuscating the change to now, in case an auditor tries compiling it on something like REMIX. 
>! This exploit allows users to always provide funds to the ICO. This is because `isDuringICO()` will always be true, as now never increments and should always stay 0, therefore now < end always ends up being true, as end should always be greater than the manipulated now, thanks to the setting in the constructor.
>! `isDuringRefund()` will always be false, hence, users will never be able to get a refund on their funds, but should have a false sense of confidence, thereby hopefully encouraging a larger sum of investments, which may at worst case look at as the greatest potential cost being the transaction fees they paid to reserve tokens, then to refund them.
>! `isDuringRefundAndICO()` will also always be false, as `now === start`, thereby the initial `now > start` condition fails always. This allows for the owner/founders to withdraw the funds within the contract whenever they please. 
