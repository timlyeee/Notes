/*
 Copyright (c) 2008-2010 Ricardo Quesada
 Copyright (c) 2011-2012 cocos2d-x.org
 Copyright (c) 2013-2016 Chukong Technologies Inc.
 Copyright (c) 2017-2020 Xiamen Yaji Software Co., Ltd.

 http://www.cocos2d-x.org

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import { legacyCC } from '../global-exports';
export class JsbBridge {
    private functionMap: Map<string, Function>;
    public static instance: JsbBridge = new JsbBridge;
    public static sendMsgToNative = (msg: string, arg?: string|null)=>{
        jsb.invokeNativeFunction(msg, arg);
    };
    /**
     * Register listener function for certain msg. each msg correspond to only one function.
     * If a function has already registered to msg m, return false. 
     * @param msgName: Message sent by Native.
     * @param f: the function be called when receiving the function 
    */
    public registerMsgListenner(msgName: string, f: Function): boolean {
        if (!this.functionMap.get(msgName)) {
            this.functionMap.set(msgName, f);
            return true;
        }
        return false;
    }
    /**
     * Method be called when msg was sent from Native
     * @param msgName Message sent by Native.
     * @param arg Argument for message listenner function. Always be string
     * @returns true if function exist and successfully be called
     */
    public onReceiveNativeMsg(msgName: string, arg?: string): boolean {
        if (!this.functionMap.get(msgName)) {
            return false;
        } 
        var f = this.functionMap.get(msgName);
        try {
            f?.call(null, arg);
            return true;
        } catch (e) {
            return false;
        }
    }
    /**
     * Remove a Listenner correspond to the msg
     * @param msgName Message sent by Native
     * @returns true if function exist and successfully be removed
     */
    public unregisterMsgListenner(msgName: string):any{
        return this.functionMap.delete(msgName);
    }
     
    constructor() {
        this.functionMap = new Map<string, Function>();
        JsbBridge.instance = this;
    }
}
legacyCC.JsbBridge = new JsbBridge;
