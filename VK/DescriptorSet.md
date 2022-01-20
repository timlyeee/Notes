# `DescriptorSet` 描述符池、描述符集合

描述符`Descriptor`是用来描述一个状态所用的变量，而一组描述符可以组成一个结构体，称为描述符集合，比如保存布局用的布局描述符集`VKDescriptorSetLayoutCreateInfo`

```cxx
typedef struct VkDescriptorSetLayoutCreateInfo {
    VkStructureType                        sType;
    const void*                            pNext;
    VkDescriptorSetLayoutCreateFlags       flags;
    uint32_t                               bindingCount;
    const VkDescriptorSetLayoutBinding*    pBindings;
} VkDescriptorSetLayoutCreateInfo;
```

通过描述符集，可以方便的实现效果的复用。更确切的来说，我们完全可以用自定义的描述符集来定制化渲染的每一个步骤。

> Think of a single descriptor as **a handle or pointer** into a resource. That resource being a Buffer or a Image, and **also holds other information**, such as the size of the buffer, or **the type of sampler** if it’s for an image. A VkDescriptorSet is a pack of those pointers that are bound together. **Vulkan does not allow you to bind individual resources in shaders**. They have to be grouped in the sets. 

## 创建一个合法的`DescriptorSet`

描述符集必须直接被从`VKDescriptorPool`中创建，然后直接从GPU的虚拟内存中分配空间。从创建到销毁，期间不能改动任何内容，除非使用`VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT`。先创建一个`VKDescriptorPool`。

```cxx
void initVK(){
    ...
    createUniformBuffer();
    createDescriptorPool();
    ...
}
void createDescriptorPool(){
    VkDescriptorPoolSize poolSize = {};
    
    //multi-type: VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER | VK_DESCRIPTOR_TYPE_X?
    poolSize.type = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    
    poolSize.descriptorCount = 1;

    VkDescriptorPoolCreateInfo poolInfo = {};
    poolInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    poolInfo.poolSizeCount = 1;
    poolInfo.pPoolSizes = &poolSize;

    poolInfo.maxSets = 1;
    VkDescriptorPool descriptorPool;

    ...

    if (vkCreateDescriptorPool(device, &poolInfo, nullptr, &descriptorPool) != VK_SUCCESS) {
        throw std::runtime_error("failed to create descriptor pool!");
    }
}

void cleanup() {
    cleanupSwapChain();

    vkDestroyDescriptorPool(device, descriptorPool, nullptr);

    ...
}

```
> [通过描述符集创建UniformBuffer](https://geek-docs.com/vulkan/vulkan-tutorial/vulkan-descriptor-pool-and-sets.html)



