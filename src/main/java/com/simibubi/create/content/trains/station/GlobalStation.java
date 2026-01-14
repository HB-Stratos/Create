package com.simibubi.create.content.trains.station;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;

import org.jetbrains.annotations.Nullable;

import com.simibubi.create.Create;
import com.simibubi.create.content.logistics.box.PackageItem;
import com.simibubi.create.content.logistics.packagePort.postbox.PostboxBlockEntity;
import com.simibubi.create.compat.computercraft.events.PackageEvent;
import com.simibubi.create.content.trains.entity.Carriage;
import com.simibubi.create.content.trains.entity.Train;
import com.simibubi.create.content.trains.graph.DimensionPalette;
import com.simibubi.create.content.trains.graph.TrackNode;
import com.simibubi.create.content.trains.signal.SingleBlockEntityEdgePoint;

import net.createmod.catnip.nbt.NBTHelper;
import net.minecraft.core.BlockPos;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.NbtUtils;
import net.minecraft.nbt.Tag;
import net.minecraft.network.FriendlyByteBuf;
import net.minecraft.server.MinecraftServer;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;

import net.neoforged.neoforge.items.IItemHandler;
import net.neoforged.neoforge.items.IItemHandlerModifiable;
import net.neoforged.neoforge.items.ItemHandlerHelper;
import net.neoforged.neoforge.server.ServerLifecycleHooks;

public class GlobalStation extends SingleBlockEntityEdgePoint {

	public String name;
	public WeakReference<Train> nearestTrain;
	public boolean assembling;

	public Map<BlockPos, GlobalPackagePort> connectedPorts;

	public GlobalStation() {
		name = "Track Station";
		nearestTrain = new WeakReference<>(null);
		connectedPorts = new HashMap<>();
	}

	@Override
	public void blockEntityAdded(BlockEntity blockEntity, boolean front) {
		super.blockEntityAdded(blockEntity, front);
		BlockState state = blockEntity.getBlockState();
		assembling =
			state != null && state.hasProperty(StationBlock.ASSEMBLING) && state.getValue(StationBlock.ASSEMBLING);
	}

	@Override
	public void read(CompoundTag nbt, HolderLookup.Provider registries, boolean migration, DimensionPalette dimensions) {
		super.read(nbt, registries, migration, dimensions);
		name = nbt.getString("Name");
		assembling = nbt.getBoolean("Assembling");
		
		// DEBUG: Log station load and WeakReference reset
		Train previousTrain = nearestTrain != null ? nearestTrain.get() : null;
		Create.LOGGER.info("[STATION-DEBUG] Loading station '{}' (ID: {}). Previous nearestTrain: {}", 
			name, id != null ? id.toString().substring(0, 8) : "null",
			previousTrain != null ? previousTrain.id.toString().substring(0, 8) : "null");
		
		nearestTrain = new WeakReference<>(null);
		
		// DEBUG: Log after reset
		Create.LOGGER.info("[STATION-DEBUG] Station '{}' (ID: {}) WeakReference reset to null during deserialization",
			name, id != null ? id.toString().substring(0, 8) : "null");

		connectedPorts.clear();
		ListTag portList = nbt.getList("Ports", Tag.TAG_COMPOUND);
		NBTHelper.iterateCompoundList(portList, c -> {
			GlobalPackagePort port = new GlobalPackagePort();
			port.address = c.getString("Address");
			port.offlineBuffer.deserializeNBT(registries, c.getCompound("OfflineBuffer"));
			port.primed = c.getBoolean("Primed");
			connectedPorts.put(NBTHelper.readBlockPos(c, "Pos"), port);
		});
	}

	@Override
	public void read(FriendlyByteBuf buffer, DimensionPalette dimensions) {
		super.read(buffer, dimensions);
		name = buffer.readUtf();
		assembling = buffer.readBoolean();
		if (buffer.readBoolean())
			blockEntityPos = buffer.readBlockPos();
	}

	@Override
	public void write(CompoundTag nbt, HolderLookup.Provider registries, DimensionPalette dimensions) {
		super.write(nbt, registries, dimensions);
		nbt.putString("Name", name);
		nbt.putBoolean("Assembling", assembling);

		nbt.put("Ports", NBTHelper.writeCompoundList(connectedPorts.entrySet(), e -> {
			CompoundTag c = new CompoundTag();
			c.putString("Address", e.getValue().address);
			c.put("OfflineBuffer", e.getValue().offlineBuffer.serializeNBT(registries));
			c.putBoolean("Primed", e.getValue().primed);
			c.put("Pos", NbtUtils.writeBlockPos(e.getKey()));
			return c;
		}));
	}

	@Override
	public void write(FriendlyByteBuf buffer, DimensionPalette dimensions) {
		super.write(buffer, dimensions);
		buffer.writeUtf(name);
		buffer.writeBoolean(assembling);
		buffer.writeBoolean(blockEntityPos != null);
		if (blockEntityPos != null)
			buffer.writeBlockPos(blockEntityPos);
	}

	public boolean canApproachFrom(TrackNode side) {
		return isPrimary(side) && !assembling;
	}

	@Override
	public boolean canNavigateVia(TrackNode side) {
		return super.canNavigateVia(side) && !assembling;
	}

	public void reserveFor(Train train) {
		Train nearestTrain = getNearestTrain();
		
		// DEBUG: Log reservation attempt
		String previousTrainId = nearestTrain != null ? nearestTrain.id.toString().substring(0, 8) : "null";
		String newTrainId = train != null ? train.id.toString().substring(0, 8) : "null";
		String trainName = train != null && train.name != null ? train.name.getString() : "unknown";
		
		Create.LOGGER.info("[STATION-DEBUG] Station '{}' (ID: {}) reserveFor() called. Previous: {}, New: {} ({})",
			name, id != null ? id.toString().substring(0, 8) : "null",
			previousTrainId, newTrainId, trainName);
		
		if (nearestTrain == null
			|| nearestTrain.navigation.distanceToDestination > train.navigation.distanceToDestination) {
			this.nearestTrain = new WeakReference<>(train);
			Create.LOGGER.info("[STATION-DEBUG] Station '{}' reservation updated to train {} ({})",
				name, newTrainId, trainName);
		} else {
			Create.LOGGER.info("[STATION-DEBUG] Station '{}' reservation kept with train {} (closer)",
				name, previousTrainId);
		}
	}

	public void cancelReservation(Train train) {
		String trainId = train != null ? train.id.toString().substring(0, 8) : "null";
		Train current = nearestTrain.get();
		String currentId = current != null ? current.id.toString().substring(0, 8) : "null";
		
		Create.LOGGER.info("[STATION-DEBUG] Station '{}' (ID: {}) cancelReservation() for train {}. Current: {}",
			name, id != null ? id.toString().substring(0, 8) : "null", trainId, currentId);
		
		if (nearestTrain.get() == train) {
			nearestTrain = new WeakReference<>(null);
			Create.LOGGER.info("[STATION-DEBUG] Station '{}' reservation cleared", name);
		} else {
			Create.LOGGER.info("[STATION-DEBUG] Station '{}' reservation NOT cleared (different train)", name);
		}
	}

	public void trainDeparted(Train train) {
		String trainId = train != null ? train.id.toString().substring(0, 8) : "null";
		String trainName = train != null && train.name != null ? train.name.getString() : "unknown";
		Create.LOGGER.info("[STATION-DEBUG] Station '{}' (ID: {}) trainDeparted() for train {} ({})",
			name, id != null ? id.toString().substring(0, 8) : "null", trainId, trainName);
		cancelReservation(train);
	}

	@Nullable
	public Train getPresentTrain() {
		Train nearestTrain = getNearestTrain();
		
		// DEBUG: Log query
		String nearestId = nearestTrain != null ? nearestTrain.id.toString().substring(0, 8) : "null";
		GlobalStation trainStation = nearestTrain != null ? nearestTrain.getCurrentStation() : null;
		String trainStationId = trainStation != null && trainStation.id != null ? trainStation.id.toString().substring(0, 8) : "null";
		boolean isPresent = nearestTrain != null && trainStation == this;
		
		Create.LOGGER.debug("[STATION-DEBUG] Station '{}' (ID: {}) getPresentTrain(): nearest={}, trainStation={}, present={}",
			name, id != null ? id.toString().substring(0, 8) : "null",
			nearestId, trainStationId, isPresent);
		
		if (nearestTrain == null || nearestTrain.getCurrentStation() != this)
			return null;
		return nearestTrain;
	}

	@Nullable
	public Train getImminentTrain() {
		Train nearestTrain = getNearestTrain();
		if (nearestTrain == null)
			return nearestTrain;
		if (nearestTrain.getCurrentStation() == this)
			return nearestTrain;
		if (!nearestTrain.navigation.isActive())
			return null;
		if (nearestTrain.navigation.distanceToDestination > 30)
			return null;
		return nearestTrain;
	}

	@Nullable
	public Train getNearestTrain() {
		Train train = this.nearestTrain.get();
		
		/* FIX COMMENTED OUT FOR INSTRUMENTATION - Uncomment to enable auto-revalidation fix
		// If the WeakReference is null, check if any train thinks it's at this station
		// This handles the case where the station was reloaded but the train wasn't
		if (train == null) {
			train = revalidateTrainPresence();
		}
		*/
		
		// DEBUG: Log every getNearestTrain() call to track null returns
		String trainId = train != null ? train.id.toString().substring(0, 8) : "null";
		String trainName = train != null && train.name != null ? train.name.getString() : "unknown";
		
		if (train == null) {
			Create.LOGGER.debug("[STATION-DEBUG] Station '{}' (ID: {}) getNearestTrain() returned NULL (WeakReference empty)",
				name, id != null ? id.toString().substring(0, 8) : "null");
		} else {
			Create.LOGGER.debug("[STATION-DEBUG] Station '{}' (ID: {}) getNearestTrain() returned train {} ({})",
				name, id != null ? id.toString().substring(0, 8) : "null", trainId, trainName);
		}
		
		return train;
	}
	
	/* FIX COMMENTED OUT FOR INSTRUMENTATION - Revalidation method
	@Nullable
	private Train revalidateTrainPresence() {
		// Iterate through all trains to find one that thinks it's at this station
		for (Train train : Create.RAILWAYS.trains.values()) {
			GlobalStation currentStation = train.getCurrentStation();
			// Use UUID comparison for robustness in case of station deserialization
			if (currentStation != null && currentStation.id.equals(this.id)) {
				// Re-establish the weak reference
				this.nearestTrain = new WeakReference<>(train);
				// Log at INFO level since this is a rare bug that should be tracked
				Create.LOGGER.info("Revalidated train presence at station '{}': Found train '{}' that was desynchronized",
					this.name, train.name.getString());
				return train;
			}
		}
		return null;
	}
	*/

	public void runMailTransfer() {
		Train train = getPresentTrain();
		if (train == null || connectedPorts.isEmpty())
			return;

		MinecraftServer server = ServerLifecycleHooks.getCurrentServer();
		Level level = server.getLevel(getBlockEntityDimension());

		for (Carriage carriage : train.carriages) {
			IItemHandlerModifiable carriageInventory = carriage.storage.getAllItems();
			if (carriageInventory == null)
				continue;

			// Import from station
			for (Entry<BlockPos, GlobalPackagePort> entry : connectedPorts.entrySet()) {
				GlobalPackagePort port = entry.getValue();
				BlockPos pos = entry.getKey();
				PostboxBlockEntity box = null;

				IItemHandlerModifiable postboxInventory = port.offlineBuffer;
				if (level != null && level.isLoaded(pos)
					&& level.getBlockEntity(pos) instanceof PostboxBlockEntity ppbe) {
					postboxInventory = ppbe.inventory;
					box = ppbe;
				}

				for (int slot = 0; slot < postboxInventory.getSlots(); slot++) {
					ItemStack stack = postboxInventory.getStackInSlot(slot);
					if (!PackageItem.isPackage(stack))
						continue;
					if (PackageItem.matchAddress(stack, port.address))
						continue;

					ItemStack result = ItemHandlerHelper.insertItemStacked(carriageInventory, stack, false);
					if (box != null)
						box.computerBehaviour.prepareComputerEvent(new PackageEvent(stack, "package_sent"));
					if (!result.isEmpty())
						continue;

					postboxInventory.setStackInSlot(slot, ItemStack.EMPTY);

					if (box == null) {
						port.primed = true;
					} else {
						box.spawnParticles();
					}

					Create.RAILWAYS.markTracksDirty();
				}
			}

			// Export to station
			for (int slot = 0; slot < carriageInventory.getSlots(); slot++) {
				ItemStack stack = carriageInventory.getStackInSlot(slot);
				if (!PackageItem.isPackage(stack))
					continue;

				for (Entry<BlockPos, GlobalPackagePort> entry : connectedPorts.entrySet()) {
					GlobalPackagePort port = entry.getValue();
					BlockPos pos = entry.getKey();
					PostboxBlockEntity box = null;

					if (!PackageItem.matchAddress(stack, port.address))
						continue;

					IItemHandler postboxInventory = port.offlineBuffer;
					if (level != null && level.isLoaded(pos)
						&& level.getBlockEntity(pos) instanceof PostboxBlockEntity ppbe) {
						postboxInventory = ppbe.inventory;
						box = ppbe;
					}

					ItemStack result = ItemHandlerHelper.insertItemStacked(postboxInventory, stack, false);
					if (box != null)
						box.computerBehaviour.prepareComputerEvent(new PackageEvent(stack, "package_received"));
					if (!result.isEmpty())
						continue;

					carriageInventory.setStackInSlot(slot, ItemStack.EMPTY);

					if (box == null) {
						port.primed = true;
					} else {
						box.spawnParticles();
					}

					Create.RAILWAYS.markTracksDirty();

					break;
				}
			}

		}
	}

}
