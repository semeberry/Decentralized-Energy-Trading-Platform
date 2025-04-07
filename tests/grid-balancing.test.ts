import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock implementation for testing Clarity contracts
const mockContractState = {
  'grid-demand': 0,
  'grid-supply': 0,
  'grid-balance-threshold': 100, // 1% threshold (100 = 1%)
  'grid-admin': 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
  'grid-regions': new Map(),
  'block-height': 100 // Mock block height
};

const mockTxSender = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';

// Mock contract functions
const mockContract = {
  'update-grid-demand': (newDemand) => {
    mockContractState['grid-demand'] = newDemand;
    return { value: true };
  },
  
  'update-grid-supply': (newSupply) => {
    mockContractState['grid-supply'] = newSupply;
    return { value: true };
  },
  
  'update-grid-region': (regionName, demand, supply) => {
    mockContractState['grid-regions'].set(regionName, {
      demand,
      supply,
      'last-updated': mockContractState['block-height']
    });
    return { value: true };
  },
  
  'is-grid-balanced': () => {
    const demand = mockContractState['grid-demand'];
    const supply = mockContractState['grid-supply'];
    const threshold = mockContractState['grid-balance-threshold'];
    
    if (demand === 0) {
      return supply === 0;
    }
    
    const diff = Math.abs(supply - demand);
    const percentage = Math.floor((diff * 10000) / demand) / 100;
    
    return percentage <= threshold;
  },
  
  'get-grid-status': () => {
    return {
      demand: mockContractState['grid-demand'],
      supply: mockContractState['grid-supply'],
      balanced: mockContract['is-grid-balanced']()
    };
  },
  
  'get-region-status': (regionName) => {
    return mockContractState['grid-regions'].get(regionName);
  },
  
  'set-balance-threshold': (newThreshold) => {
    if (mockTxSender !== mockContractState['grid-admin']) {
      return { error: 1 };
    }
    
    mockContractState['grid-balance-threshold'] = newThreshold;
    return { value: true };
  },
  
  'transfer-admin': (newAdmin) => {
    if (mockTxSender !== mockContractState['grid-admin']) {
      return { error: 1 };
    }
    
    mockContractState['grid-admin'] = newAdmin;
    return { value: true };
  }
};

describe('Grid Balancing Contract', () => {
  beforeEach(() => {
    // Reset the mock state before each test
    mockContractState['grid-demand'] = 0;
    mockContractState['grid-supply'] = 0;
    mockContractState['grid-balance-threshold'] = 100;
    mockContractState['grid-admin'] = mockTxSender;
    mockContractState['grid-regions'] = new Map();
    mockContractState['block-height'] = 100;
  });
  
  it('should update grid demand and supply', () => {
    mockContract['update-grid-demand'](1000);
    mockContract['update-grid-supply'](1000);
    
    const status = mockContract['get-grid-status']();
    expect(status).toEqual({
      demand: 1000,
      supply: 1000,
      balanced: true
    });
  });
  
  it('should detect grid imbalance', () => {
    mockContract['update-grid-demand'](1000);
    mockContract['update-grid-supply'](1050); // 5% more supply than demand
    
    const status = mockContract['get-grid-status']();
    expect(status.balanced).toBe(false);
  });
  
  it('should update a grid region', () => {
    mockContract['update-grid-region']('California', 500, 450);
    
    const region = mockContract['get-region-status']('California');
    expect(region).toEqual({
      demand: 500,
      supply: 450,
      'last-updated': mockContractState['block-height']
    });
  });
  
  it('should set a new balance threshold', () => {
    mockContract['set-balance-threshold'](500); // 5% threshold
    
    // Now a 5% difference should be balanced
    mockContract['update-grid-demand'](1000);
    mockContract['update-grid-supply'](1050); // 5% more supply than demand
    
    const status = mockContract['get-grid-status']();
    expect(status.balanced).toBe(true);
  });
  
  it('should transfer admin rights', () => {
    const newAdmin = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
    mockContract['transfer-admin'](newAdmin);
    
    expect(mockContractState['grid-admin']).toBe(newAdmin);
  });
});
